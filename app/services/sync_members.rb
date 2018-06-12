# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Updates local database with records from legacy database
class SyncMembers
  attr_reader :event, :remote_members, :local_members, :sync_errors
  def initialize(event)
    @event = event
    @sync_errors = ErrorReport.new(self.class, @event)
    @remote_members = retrieve_remote_members
    @local_members = @event.memberships.includes(:person)
    prune_members
    sync_memberships
    check_max_participants
    sync_errors.send_report
  end

  def sync_memberships
    remote_members.each do |rm|
      remote_member = fix_remote_fields(rm)
      local_member = find_local_membership(remote_member)

      if local_member.nil?
        create_new_membership(remote_member)
      else
        membership = update_record(local_member, remote_member['Membership'])
        person = update_record(local_member.person, remote_member['Person'])
        save_membership(membership)
      end
    end
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

  def prune_members
    remote_ids = remote_members.map { |m| m['Person']['legacy_id'].to_i }
    remote_emails = remote_members.map { |m| m['Person']['email'] }

    Event.find(@event.id).memberships.includes(:person).each do |m|
      m.destroy unless remote_ids.include?(m.person.legacy_id) ||
        remote_emails.include?(m.person.email)
    end
  end

  def check_max_participants
    confirmed = 0
    invited = 0
    undecided = 0
    nyninvited = 0
    declined = 0
    Event.find(@event.id).memberships.each do |membership|
      confirmed += 1 if membership.attendance == 'Confirmed'
      invited += 1 if membership.attendance == 'Invited'
      undecided += 1 if membership.attendance == 'Undecided'
      nyninvited += 1 if membership.attendance == 'Not Yet Invited'
      declined += 1 if membership.attendance == 'Declined'
    end

    total_invited = confirmed + invited + undecided
    if @event.max_participants - total_invited < 0
      msg = "Membership Totals:\n"
      msg += "Confirmed participants: #{confirmed}\n"
      msg += "Invited participants: #{invited}\n"
      msg += "Undecided participants: #{undecided}\n"
      msg += "Not Yet Invited participants: #{nyninvited}\n"
      msg += "Declined participants: #{declined}\n\n"
      msg += "Total invited: #{total_invited}\n"
      msg += "#{@event.code} Maximum allowed: #{@event.max_participants}\n"

      sync_errors.add(@event, "#{@event.code} is overbooked!\n\n#{msg}")
    end
  end

  def retrieve_remote_members
    lc = LegacyConnector.new
    remote_members = lc.get_members(event)

    if remote_members.nil? || remote_members.blank?
      sync_errors.add(lc,
                      "Unable to retrieve any remote members for #{event.code}")
      sync_errors.send_report
      raise 'NoResultsError'
    end
    remote_members
  end

  def fix_remote_fields(remote_member)
    unless remote_member['Person']['email'].blank?
      remote_member['Person']['email'] =
        remote_member['Person']['email'].downcase.strip
    end

    unless remote_member['Person']['cc_email'].blank?
      remote_member['Person']['cc_email'] =
        remote_member['Person']['cc_email'].downcase.strip
    end

    if remote_member['Person']['updated_by'].blank?
      remote_member['Person']['updated_by'] = 'Workshops importer'
    end

    if remote_member['Membership']['updated_by'].blank?
      remote_member['Membership']['updated_by'] = 'Workshops importer'
    end

    if remote_member['Person']['updated_at'].blank? ||
       remote_member['Person']['updated_at'] == '0000-00-00 00:00:00'
      remote_member['Person']['updated_at'] = DateTime.current
    else
      remote_member['Person']['updated_at'] =
        Time.at(remote_member['Person']['updated_at'])
            .in_time_zone(@event.time_zone)
    end

    if remote_member['Membership']['updated_at'].blank? ||
       remote_member['Membership']['updated_at'] == '0000-00-00 00:00:00'
      remote_member['Membership']['updated_at'] = DateTime.current
    else
      remote_member['Membership']['updated_at'] =
        Time.at(remote_member['Membership']['updated_at'])
            .in_time_zone(@event.time_zone)
    end

    unless remote_member['Membership']['replied_at'].blank? ||
           remote_member['Membership']['replied_at'] == '0000-00-00 00:00:00'
      remote_member['Membership']['replied_at'] =
        DateTime.parse(remote_member['Membership']['replied_at'].to_s)
                .in_time_zone(@event.time_zone)
    end

    if remote_member['Membership']['role'] == 'Backup Participant'
      remote_member['Membership']['attendance'] = 'Not Yet Invited'
    end

    remote_member
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
    return true if value == true || value == 1
    return false
  end

  def boolean_fields(obj)
    fields = []
    obj.attribute_names.each do |field|
      fields << field if obj.type_for_attribute(field).type == :boolean
    end
    fields
  end

  # local record, remote hash
  def update_record(local, remote)
    booleans = boolean_fields(local)

    remote.each_pair do |k, v|
      next if v.blank?
      v = prepare_value(k, v)
      next if k == 'updated_at' && local.updated_at.utc == v
      v = bool_value(v) if booleans.include?(k)

      unless local.send(k).eql? v
        if k.eql? 'email'
          local = update_email(local, remote)
        else
          local.send("#{k}=", v)
        end
      end
    end
    local
  end

  def prepare_value(k, v)
    v = v.to_i if k.eql? 'legacy_id'
    if k.to_s.include?('_date') || k.to_s.include?('_at')
      v = nil if v == '0000-00-00 00:00:00'
      v = DateTime.parse(v.to_s) unless v.nil?
    end
    v = v.utc if v && k.to_s.include?('_at')
    v = v.strip if v.respond_to? :strip
    v
  end

  def update_email(local_person, remote_person_hash)
    other_person = Person.find_by_email(remote_person_hash['email'])
    unless other_person.nil? || other_person.id == local_person.id
      # local_person has the same legacy_id as remote, but different email.
      # other_person has same email as remote, but is not a member of this event
      # and has different legacy_id. Merge data and destroy other_person:
      replace_person(replace: other_person, replace_with: local_person)
    end
    local_person.email = remote_person_hash['email']
    local_person
  end

  def replace_person(replace: other_person, replace_with: person)
    replace.memberships.each do |m|
      if replace_with.memberships.select { |rm| rm.event_id == m.id }.blank?
        m.person = replace_with
        m.save!
      end
    end

    Lecture.where(person_id: replace.id).each do |l|
      l.person = replace_with
      l.save
    end

    user_account = User.where(person_id: replace.id).first
    unless user_account.nil?
      user_account.person = replace_with
      user_account.email = replace_with.email
      user_account.skip_reconfirmation!
      user_account.save
    end

    # there can be only one!
    Person.find(replace.id).destroy
  end

  def save_person(person)
    person.member_import = true
    if person.save
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
end
