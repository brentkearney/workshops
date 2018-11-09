# app/jobs/email_site_feedback_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to send message from feedback form
class EmailSiteFeedbackJob < ApplicationJob
  queue_as :urgent

  def perform(section, membership_id, message)
    membership = Membership.find_by_id(membership_id)
    StaffMailer.site_feedback(section: section, membership: membership,
      message: message).deliver_now
  end
end
