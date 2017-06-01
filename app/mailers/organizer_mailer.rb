# Copyright (c) 2016 Banff International Research Station
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
    @membership_url = Setting.Site['app_url'] + "/#{event_membership_path(@event)}"

    @organization = 'Staff'
    unless Setting.Locations["#{membership.event.location}"].nil?
      @organization = Setting.Locations["#{membership.event.location}"]['Name']
    end

    email = '"' + @organizer.name + '" <' + @organizer.email + '>'
    subject = '[' + @event.code + '] Membership invitation reply'
    mail(to: email, subject: subject, 'Importance': 'High', 'X-Priority': 1)
  end
end
