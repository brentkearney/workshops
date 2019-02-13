# app/services/syncable.rb
# Copyright (c) 2018 Banff International Research Station
#
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# methods for SyncMember(s) & SyncPerson
module Syncable
  attr_writer :event, :local_members

  def event
    @event ||= ::Event.new
  end

  def local_members
    @local_members ||= event.memberships.includes(:person)
  end

  def fix_remote_fields(h)
    h['Person'] = Person.new.attributes if h['Person'].blank?
    h['Membership'] = Membership.new.attributes if h['Membership'].blank?

    h['Person'] = tidy_emails(h['Person'])
    h = update_updateds(h)

    if h['Membership']['role'] == 'Backup Participant'
      h['Membership']['attendance'] = 'Not Yet Invited'
    end
    h
  end

  def find_local_membership(remote_member)
    local_membership = local_members.select do |membership|
      membership.person.legacy_id == remote_member['Person']['legacy_id']
    end.first

    if local_membership.nil?
      local_membership = local_members.select do |membership|
        membership.person.email == remote_member['Person']['email']
      end.first
    end
    local_membership
  end

  def create_new_membership(remote_member)
    local_person = find_and_update_person(remote_member['Person'])
    if local_person.valid?
      if local_members.select { |m| m.person_id == local_person.id }.blank?
        membership = Membership.new(remote_member['Membership'])
        membership.person_id = local_person.id
        membership.event_id = @event.id
        save_membership(membership)
      end
    end
  end

  def get_local_person(remote_person)
    Person.find_by(legacy_id: remote_person['legacy_id'].to_i) ||
      Person.find_by(email: remote_person['email'])
  end

  def find_and_update_person(remote_person)
    local_person = get_local_person(remote_person)
    if local_person.blank?
      local_person = save_person(Person.new(remote_person))
    else
      local_person = update_record(local_person, remote_person)
      save_person(local_person)
    end
    local_person
  end

  def bool_value(value)
    value == true || value == 1
  end

  def boolean_fields(obj)
    return if obj.nil?
    fields = []
    obj.attribute_names.each do |field|
      fields << field if obj.type_for_attribute(field).type == :boolean
    end
    fields
  end

  # local record, remote hash
  def update_record(local, remote)
    remote_updated = prepare_value('updated_at', remote['updated_at'])
    return local if local.updated_at >= remote_updated
    Rails.logger.debug "update_record: #{local.inspect}\n\nremote: #{remote.inspect}\n\n"
    booleans = boolean_fields(local)
    remote.each_pair do |k, v|
      next if v.blank?
      v = prepare_value(k, v)
      next if k == 'updated_at' && local.updated_at.utc == v
      v = bool_value(v) if booleans.include?(k)

      next if k == 'invited_by'
      if k == 'invited_on'
        if local.invited_on.blank? || local.invited_on.to_i < v.to_i
          local.invited_on = v
          local.invited_by = remote['invited_by']
        end
      end

      next if k == 'invited_on'

      unless local.send(k).eql? v
        # if its an email change, User account may also need updating
        # if its a legacy_id change, also update event associations on legacydb
        if k == 'legacy_id' || k == 'email'
          local = resolve_duplicates(local, remote, k)
        else
          local.send("#{k}=", v)
        end
      end
    end
    local
  end

  # find duplicate Person records based on email or legacy_id (mode)
  def resolve_duplicates(local, remote, mode)
    person = local
    other_person = Person.find_by("#{mode}": remote[mode])
    if other_person.blank?
      replace_remote(Person.new(remote), local) if mode == 'legacy_id'
      update_email(local, remote['email']) if mode == 'email'
    else
      person = merge_person_records(local, other_person)
    end
    person
  end

  def update_email(person, email)
    person.email = email
    update_user_account(person, person, email)
  end

  # keep the record with most associated data, merge the other
  def merge_person_records(p1, p2)
    replace_with = ComparePersons.new(p1, p2).better_record
    replace = replace_with.eql?(p1) ? p2 : p1
    replace_person(replace: replace, replace_with: replace_with)
    replace_with
  end

  def prepare_value(k, v)
    v = v.to_i if k.eql? 'legacy_id'
    if k.to_s.include?('_date') || k.to_s.include?('_at')
      v = nil if v == '0000-00-00 00:00:00'
      v = convert_to_time(v) unless v.nil?
    end
    v = v.utc if v && k.to_s.include?('_at')
    v = v.strip if v.respond_to? :strip
    v
  end

  def convert_to_time(v)
    return Time.at(v) if v.is_a?(Integer)
    DateTime.parse(v.to_s)
  end

  def replace_person(replace: other_person, replace_with: person)
    replace.memberships.each do |m|
      replace_with_membership = Membership.where(event: m.event,
                                                person: replace_with).first
      if replace_with_membership.blank?
        m.update(person: replace_with)
      else
        Invitation.where(membership: m).each do |i|
          i.update(membership: replace_with_membership)
        end
        m.sync_memberships = true
        m.delete
      end
    end

    Lecture.where(person_id: replace.id).each do |l|
      l.update(person: replace_with)
    end

    if User.find_by_person_id(replace_with.id).blank?
      update_user_account(replace, replace_with, replace_with.email)
    end

    # Update legacy database
    replace_remote(replace, replace_with)

    # there can be only one!
    replace.delete
  end

  def update_user_account(person, replace_with, email)
    user_account = User.find_by_person_id(person.id)
    unless user_account.nil?
      user_account.person = replace_with
      user_account.email = email
      user_account.skip_reconfirmation!
      user_account.save
    end
  end

  def replace_remote(replace, replace_with)
    return if replace.legacy_id.blank? || replace_with.legacy_id.blank?
    ReplacePersonJob.perform_later(replace.legacy_id, replace_with.legacy_id)
  end

  def save_person(person)
    person.member_import = true
    if person.valid? && person.save
      unless person.previous_changes.empty?
        Rails.logger.info "\n\n* Saved #{@event.code} person: #{person.name}\n"
      end
    else
      Rails.logger.error "\n\n" + "* Error saving #{@event.code} person:
        #{person.name}, #{person.errors.full_messages}".squish + "\n"
      sync_errors.add(person)
    end
    person
  end

  def save_membership(membership)
    membership.person.member_import = true
    membership.sync_memberships = true
    if membership.save
      unless membership.previous_changes.empty?
        Rails.logger.info "\n\n" + "* Saved #{membership.event.code} membership for
          #{membership.person.name}".squish + "\n"
      end
    else
      Rails.logger.error "\n\n" + "* Error saving #{membership.event.code} membership for
        #{membership.person.name}:
        #{membership.errors.full_messages}".squish + "\n"
      sync_errors.add(membership)
    end
    membership
  end

  def tidy_emails(p)
    p['email'] = p['email'].downcase.strip unless p['email'].blank?
    p['cc_email'] = p['cc_email'].downcase.strip unless p['cc_email'].blank?
    p
  end

  def update_updateds(h)
    h.each do |k, attr|
      if attr.key?('updated_by')
        attr['updated_by'] = 'Workshops importer' if attr['updated_by'].blank?
      end
      attr['updated_at'] = fixtime(attr['updated_at']) if attr.key?('updated_at')
    end
    h
  end

  def fixtime(val)
    return DateTime.current if blank_time?(val)
    val
  end

  def blank_time?(val)
    val.blank? || val == '0000-00-00 00:00:00'
  end
end
