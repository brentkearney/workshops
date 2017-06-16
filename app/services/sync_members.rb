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
    sync_memberships
  end

  def sync_memberships
    remote_members.each do |rm|
      remote_member = fix_remote_fields(rm)
      local_person = update_person(remote_member['Person'])
      update_membership(remote_member['Membership'], local_person)
    end

    prune_members
    sync_errors.send_report
  end

  def prune_members
    remote_ids = remote_members.map { |m| m['Person']['legacy_id'].to_i }
    Event.find(@event.id).memberships.includes(:person).each do |m|
      m.destroy unless remote_ids.include?(m.person.legacy_id)
    end
  end

  def retrieve_remote_members
    lc = LegacyConnector.new
    remote_members = lc.get_members(event)

    if remote_members.empty?
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
        remote_member['Person']['email'].downcase
    end

    unless remote_member['Person']['cc_email'].blank?
      remote_member['Person']['cc_email'] =
        remote_member['Person']['cc_email'].downcase
    end

    if remote_member['Person']['updated_by'].blank?
      remote_member['Person']['updated_by'] = 'Workshops importer'
    end

    if remote_member['Membership']['updated_by'].blank?
      remote_member['Membership']['updated_by'] = 'Workshops importer'
    end

    if remote_member['Person']['updated_at'].blank?
      remote_member['Person']['updated_at'] = Time.now
    else
      remote_member['Person']['updated_at'] =
        Time.at(remote_member['Person']['updated_at'])
            .in_time_zone(@event.time_zone)
    end

    if remote_member['Membership']['updated_at'].blank?
      remote_member['Membership']['updated_at'] = Time.now
    else
      remote_member['Membership']['updated_at'] =
        Time.at(remote_member['Membership']['updated_at'])
            .in_time_zone(@event.time_zone)
    end

    unless remote_member['Membership']['replied_at'].blank?
      remote_member['Membership']['replied_at'] =
        DateTime.parse(remote_member['Membership']['replied_at'].to_s)
                .in_time_zone(@event.time_zone)
    end

    if remote_member['Membership']['role'] == 'Backup Participant'
      remote_member['Membership']['attendance'] = 'Not Yet Invited'
    end

    remote_member
  end

  def update_person(remote_person)
    local_person = get_local_person(remote_person)

    if local_person.nil?
      local_person = save_person(Person.new(remote_person))
    else
      updated_person = update_record(local_person, remote_person)
      if updated_person
        local_person = updated_person
        save_person(local_person)
      end
    end
    local_person
  end

  # local record, remote hash
  def update_record(local, remote)
    updated = false
    remote.each_pair do |k, v|
      next if v.blank?
      v = prepare_value(k, v)

      unless local.send(k).eql? v
        if k.eql? 'email'
          local = update_email(local, remote, v)
        else
          local.send("#{k}=", v)
        end
        updated = true
      end
    end
    return local if updated
  end

  def prepare_value(k, v)
    v = v.to_i if k.eql? 'legacy_id'
    v = v.utc if k.to_s.include?('_at')

    if k.to_s.include?('_date')
      v = nil if v == '0000-00-00 00:00:00'
      v = Date.parse(v.to_s) unless v.nil?
    end

    v.strip! if v.respond_to? :strip!
    v
  end

  def update_email(local_person, remote_person_hash, new_email)
    other_person = Person.find_by_email(new_email)
    if other_person.nil?
      local_person.email = new_email
    else
      # email is the same, so update_record will skip that field
      updated_other = update_record(other_person, remote_person_hash)
      other_person = updated_other if updated_other
      replace_person(local_person, other_person)
      local_person = other_person
    end
    local_person
  end

  def replace_person(person, replacement)
    person.memberships.each do |m|
      unless replacement.events.include?(m.event)
        m.person = replacement
        m.save
      end
    end

    Lecture.where(person: person).each do |l|
      l.person = replacement
      l.save
    end

    user_account = User.where(person_id: person.id).first
    unless user_account.nil?
      user_account.person_id = replacement.id
      user_account.email = replacement.email
      user_account.skip_reconfirmation!
      user_account.save
    end

    # there can be only one!
    person.destroy
  end

  def get_local_person(remote_person)
    Person.where(legacy_id: remote_person['legacy_id'].to_i).first ||
      Person.find_by(email: remote_person['email'])
  end

  def save_person(person)
    if person.save
      Rails.logger.info "\n\n* Saved #{@event.code} person: #{person.name}\n"
    else
      Rails.logger.error "\n\n* Error saving #{@event.code} person: #{person.name}, #{person.errors.full_messages}\n"
      sync_errors.add(person)
    end
    person
  end

  def update_membership(remote_member, local_person)
    local_membership = local_members.select do |m|
      m.person_id.to_i == local_person[:id].to_i
    end.first

    if local_membership.nil?
      local_membership = Membership.new(remote_member)
      local_membership.event = event
      local_membership.person = local_person
      save_membership(local_membership)
    else
      updated_member = update_record(local_membership, remote_member)
      local_membership = save_membership(updated_member) if updated_member
    end
    local_membership
  end

  def save_membership(membership)
    if membership.save
      Rails.logger.info "\n\n* Saved #{@event.code} membership for #{membership.person.name}\n"
    else
      Rails.logger.error "\n\n* Error saving #{@event.code} membership for #{membership.person.name}: #{membership.errors.full_messages}\n"
      sync_errors.add(membership)
    end
    membership
  end
end
