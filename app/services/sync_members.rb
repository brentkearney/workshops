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
    @remote_members = get_remote_members
    @local_members = @event.memberships.includes(:person)
    run
  end

  def run
    remote_members.each do |remote_member|
      translated_member = fix_remote_fields(remote_member)
      local_person = update_person(translated_member['Person'])
      update_membership(translated_member['Membership'], local_person)
    end

    sync_errors.send_report
  end

  def get_remote_members
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

    if remote_member['Membership']['role'] == 'Backup Participant'
      remote_member['Membership']['attendance'] = 'Not Yet Invited'
    end

    remote_member
  end

  def update_person(remote_person)
    local_person = get_local_person(remote_person)

    if local_person.nil?
      local_person = Person.new(remote_person)
      save_person(local_person)
    else
      Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
      Rails.logger.debug "local_person: #{local_person.attributes}\n"
      Rails.logger.debug "remote_person: #{remote_person}\n"

      if local_person.attributes.except(:id) == remote_person
        Rails.logger.debug "\n* local_person.name attributes match, not updating.\n"
      else
        remote_person.each_pair do |k, v|
          local_person[k] = v unless v.blank?
        end
        save_person(local_person)
      end
      Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
    end

    local_person
  end

  def get_local_person(remote_person)
    member = local_members.select do |m|
      m.person_id == remote_person['legacy_id']
    end.first

    return member.person unless member.nil?
    Person.find_by(email: remote_person['email'])
  end

  def save_person(person)
    if person.save
      Rails.logger.info "\n* Saved #{@event.code} person: #{person.name}\n"
    else
      Rails.logger.error "\n* Error saving #{@event.code} person: #{person.name}, #{person.errors.full_messages}\n"
      sync_errors.add(person)
    end
  end

  def update_membership(remote_member, local_person)
    local_membership = local_members.select do |m|
      m.person_id == local_person[:id]
    end.first

    if local_membership.nil?
      local_membership = Membership.new(remote_member)
      local_membership.event = event
      local_membership.person = local_person
      save_membership(local_membership)
    else
      if local_membership.attributes.except(:id) == remote_member
        Rails.logger.debug "\n* Local membership is the same, not updating.\n"
      else
        remote_member.each_pair do |k, v|
          local_membership[k] = v unless v.blank?
        end
        save_membership(local_membership)
      end
    end
  end

  def save_membership(membership)
    if membership.save
      Rails.logger.info "\n* Saved #{@event.code} membership for #{membership.person.name}\n"
    else
      Rails.logger.error "\n* Error saving #{@event.code} membership for #{membership.person.name}: #{membership.errors.full_messages}\n"
      sync_errors.add(membership)
    end
  end
end
