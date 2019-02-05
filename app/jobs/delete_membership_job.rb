# app/jobs/delete_membership_job.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to legacy database to update a membership
class DeleteMembershipJob < ApplicationJob
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    membership = arguments[0]
    event = Event.find_by_code(membership['event_id'])
    message = membership.merge(error: error)
    StaffMailer.notify_sysadmin(event, message).deliver_now

    if error.message != 'JSON::ParserError'
      retry_job wait: 1.minutes, queue: :default
    end
  end

  def perform(membership)
    LegacyConnector.new.delete_member(membership)
  end
end
