# Copyright (c) 2016 Brent Kearney
#
# This file is part of Workshops.
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
      update_membership(remote, local_person) unless local_person.id.nil?
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
      remote['Person']['updated_at'] = Time.at(remote['Person']['updated_at'])
    end

    if remote['Membership']['updated_at'].blank?
      remote['Membership']['updated_at'] = Time.now
    else
      remote['Membership']['updated_at'] = Time.at(remote['Membership']['updated_at'])
    end

    if remote['Membership']['role'] == 'Backup Participant'
      remote['Membership']['attendance'] == 'Not Yet Invited'
    end

    remote
  end
  
  def update_person(remote)
    local_person = get_local_person(remote)
    already_up_to_date = false

    if local_person.nil?
      local_person = Person.new(remote['Person'])
    else
      if remote['Person']['updated_at'] > local_person.updated_at
        remote['Person'].each_pair do |k,v|
          local_person[k] = v unless v.blank?
        end
      else
        already_up_to_date = true
      end
    end

    if local_person.valid?
      local_person.save! unless already_up_to_date
    else
      @sync_errors['People'] << local_person
    end

    local_person
  end

  def get_local_person(remote)
    Person.find_by(legacy_id: remote['Person']['legacy_id']) || Person.find_by(email: remote['Person']['email'])
  end

  def update_membership(remote, local_person)
    local_membership = Membership.where(event: @event, person: local_person).first
    already_up_to_date = false

    if local_membership.nil?
      local_membership = Membership.new(remote['Membership'])
      local_membership.event = @event
      local_membership.person = local_person
    else
      if remote['Membership']['updated_at'] > local_membership.updated_at
        remote['Membership'].each_pair do |k,v|
          local_membership[k] = v unless v.blank?
        end
        save_membership(local_membership)
      end
    end
    
  end

  def save_membership(local_membership)
    if local_membership.valid? && local_membership.save
      Rails.logger.debug "* Saved #{@event.code} membership: #{local_person.name}"
    else
      @sync_errors['Memberships'] << local_membership
    end
  end
  
end