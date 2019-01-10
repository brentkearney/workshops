# Copyright (c) 2018 Banff International Research Station
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
  include Syncable

  def initialize(event)
    @event = event
    return if event.nil? || recently_synced?
    @sync_errors = ErrorReport.new(self.class, @event)
    @remote_members = retrieve_remote_members
    @local_members = event.memberships.includes(:person)
    sync_memberships
    event.set_sync_time
    check_max_participants
    sync_errors.send_report
  end

  def recently_synced?
    return false if event.nil? || event.sync_time.blank?
    # return true if Rails.env.development?
    Time.now - event.sync_time < 5.minutes
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

  def sync_memberships
    fixed_remote_members = []
    remote_members.each do |rm|
      remote_member = fix_remote_fields(rm)
      fixed_remote_members << remote_member
      local_member = find_local_membership(remote_member)

      if local_member.nil?
        create_new_membership(remote_member)
      else
        person = update_record(local_member.person, remote_member['Person'])
        membership = update_record(local_member, remote_member['Membership'])
        membership.person = person
        save_membership(membership)
      end
    end
    remote_members = fixed_remote_members
    prune_members
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
    observers = 0
    Event.find(@event.id).memberships.each do |membership|
      confirmed += 1 if membership.attendance == 'Confirmed'
      invited += 1 if membership.attendance == 'Invited'
      undecided += 1 if membership.attendance == 'Undecided'
      nyninvited += 1 if membership.attendance == 'Not Yet Invited'
      declined += 1 if membership.attendance == 'Declined'

      if membership.role == 'Observer'
        observers += 1
        confirmed -= 1 if membership.attendance == 'Confirmed'
        invited -= 1 if membership.attendance == 'Invited'
      end
    end

    total_invited = confirmed + invited + undecided
    if @event.max_participants - total_invited < 0
      msg = "Membership Totals:\n"
      msg += "Confirmed participants: #{confirmed}\n"
      msg += "Invited participants: #{invited}\n"
      msg += "Undecided participants: #{undecided}\n"
      msg += "Not Yet Invited participants: #{nyninvited}\n"
      msg += "Declined participants: #{declined}\n\n"
      msg += "Total invited participants: #{total_invited}\n"
      msg += "Total observers: #{observers}\n"
      msg += "#{@event.code} Maximum allowed: #{@event.max_participants}\n"

      sync_errors.add(@event, "#{@event.code} is overbooked!\n\n#{msg}")
    end
  end
end
