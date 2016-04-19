# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SyncEventMembersJob < ActiveJob::Base
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    if error.message == 'NoResultsError'
      retry_job wait: 5.minutes, queue: :default
    end
  end

  def perform(event)
    SyncMembers.new(event)
  end
end

