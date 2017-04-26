# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class OrganizerMailer < ApplicationMailer
  app_email = Setting.Site['application_email'] unless Setting.Site.blank?
  if Setting.Site.blank? || app_email.nil?
    app_email = ENV['DEVISE_EMAIL']
  end

  default from: app_email

  def rsvp_notice(membership, organizer_message = nil)
    @old_attendance = membership.attendance_was
    @new_attendance = membership.attendance
    @member = membership.person
    @event = membership.event
    @organizer = @event.organizer
    @message_to_organizer = organizer_message

    @organization = 'Staff'
    unless Setting.Locations["#{membership.event.location}"].nil?
      @organization = Setting.Locations["#{membership.event.location}"]['Name']
    end

    email = '"' + @organizer.name + '" <' + @organizer.email + '>'
    subject = '[' + membership.event.code + '] Membership invitation reply'
    mail(to: email, subject: subject, 'Importance': 'High', 'X-Priority': 1)
  end
end
