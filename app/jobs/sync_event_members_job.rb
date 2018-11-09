# app/jobs/sync_event_members_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to legacy database to sync membership data
class SyncEventMembersJob < ApplicationJob
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    event_id = arguments[0]
    StaffMailer.notify_sysadmin(event_id, error).deliver_now

    if error.message == 'NoResultsError'
      retry_job wait: 5.minutes, queue: :default
    end
  end

  def perform(event_id)
    SyncMembers.new(Event.find_by_id(event_id))
  end
end
