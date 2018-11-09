# app/jobs/unauthorized_subgroup_bounce_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates BounceMailer to reply to unauthorized senders
class UnauthorizedSubgroupBounceJob < ApplicationJob
  queue_as :urgent

  def perform(params)
    BounceMailer.unauthorized_subgroup(params).deliver_now
  end
end
