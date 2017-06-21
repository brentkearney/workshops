# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to legacy database to update a membership
class SyncMembershipJob < ActiveJob::Base
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    if error.message == 'JSON::ParserError'
      membership = arguments[0]
      StaffMailer.notify_sysadmin(membership.event, error).deliver_now
    else
      retry_job wait: 10.minutes, queue: :default
    end
  end

  def perform(membership)
    LegacyConnector.new.update_member(membership)
  end
end

