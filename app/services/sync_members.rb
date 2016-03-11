# Copyright (c) 2016 Banff International Research Station
#
# This file is part of Workshops. Workshops is licensed under
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Updates local database with records from legacy database
class SyncMembers
  def initialize(event)
    @event = event
    @remote_members = get_remote_members("#{@event.code}")
    @sync_errors = { 'Event' => @event, 'People' => Array.new, 'Memberships' => Array.new }
  end

  def run
    @remote_members.each do |remote|
      remote = fix_remote_fields(remote)
      local_person = update_person(remote)
      update_membership(remote, local_person)
    end

    if @sync_errors['People'].count > 0 || @sync_errors['Memberships'].count > 0
      StaffMailer.event_sync(@sync_errors).deliver_now
    end
  end

  
  private

  def get_remote_members(code)
    lc = LegacyConnector.new
    remote_members = lc.get_members("#{@event.code}")
    if remote_members.empty?
      Rails.logger.error "\n\n****************************\n\n!! Unable to retrieve any remote members for #{@event.code} !!\n\n****************************\n\n"
      raise 'NoResultsError'
    end
    remote_members
  end

  def fix_remote_fields(remote)
    if remote['Person']['updated_by'].blank?
      remote['Person']['updated_by'] = 'Workshops importer'
    end

    if remote['Membership']['updated_by'].blank?
      remote['Membership']['updated_by'] = 'Workshops importer'
    end

    if remote['Person']['updated_at'].blank?
      remote['Person']['updated_at'] = Time.now
    else
      remote['Person']['updated_at'] = Time.at(remote['Person']['updated_at']).in_time_zone(@event.time_zone)
    end

    if remote['Membership']['updated_at'].blank?
      remote['Membership']['updated_at'] = Time.now
    else
      remote['Membership']['updated_at'] = Time.at(remote['Membership']['updated_at']).in_time_zone(@event.time_zone)
    end

    if remote['Membership']['role'] == 'Backup Participant'
      remote['Membership']['attendance'] == 'Not Yet Invited'
    end

    remote
  end
  
  def update_person(remote)
    local_person = get_local_person(remote)

    if local_person.nil?
      local_person = Person.new(remote['Person'])
      save_person(local_person)
    else
      remote_update = remote['Person']['updated_at'].in_time_zone(@event.time_zone)
      local_update = local_person.updated_at.in_time_zone(@event.time_zone)
      if remote_update > local_update
        remote['Person'].each_pair do |k,v|
          local_person[k] = v unless v.blank?
        end
        save_person(local_person)
      end
    end
    
    local_person
  end

  def save_person(person)
    if person.valid? && person.save
      Rails.logger.debug "* Saved #{@event.code} person: #{person.name}"
    else
      @sync_errors['People'] << person
    end
  end
  
  def get_local_person(remote)
    Person.find_by(legacy_id: remote['Person']['legacy_id']) || Person.find_by(email: remote['Person']['email'])
  end

  def update_membership(remote, person)
    local_membership = Membership.where(event: @event, person: person).first

    if local_membership.nil?
      local_membership = Membership.new(remote['Membership'])
      local_membership.event = @event
      local_membership.person = person
      save_membership(local_membership)
    else
      remote_update = remote['Membership']['updated_at'].in_time_zone(@event.time_zone)
      local_update = local_membership.updated_at.in_time_zone(@event.time_zone)
      if remote_update > local_update
        remote['Membership'].each_pair do |k,v|
          local_membership[k] = v unless v.blank?
        end
        save_membership(local_membership)
      end
    end
  end

  def save_membership(membership)
    if membership.valid? && membership.save
      Rails.logger.debug "* Saved #{@event.code} membership: #{membership.person.name}"
    else
      @sync_errors['Memberships'] << membership
    end
  end

end
