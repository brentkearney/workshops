# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates BounceMailer to reply to non-member senders
class EmailFromNonmemberBounceJob < ActiveJob::Base
  queue_as :urgent

  def perform(params)
    BounceMailer.non_member(params).deliver_now
  end
end
