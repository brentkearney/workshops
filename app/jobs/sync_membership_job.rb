# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to legacy database to update a membership
class SyncMembershipJob < ActiveJob::Base
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    membership_id = arguments[0]
    membership = Membership.find_by_id(membership_id) unless membership_id.nil?
    event = membership.nil? ? nil : membership.event
    StaffMailer.notify_sysadmin(event, error).deliver_now

    if error.message != 'JSON::ParserError'
      retry_job wait: 1.minutes, queue: :default
    end
  end

  def perform(membership_id)
    LegacyConnector.new.update_member(membership_id)
  end
end
