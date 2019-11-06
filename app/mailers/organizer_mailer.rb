# Copyright (c) 2018 Banff International Research Station
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

# Email notices for the workshop organizer
class OrganizerMailer < ApplicationMailer
  def rsvp_notice(membership, args)
    old_attendance = args['attendance_was'] || 'Invited'
    new_attendance = args['attendance'] || 'Invited'

    @attendance_msg = "Attendance status is: #{new_attendance}."
    unless old_attendance == new_attendance
      @attendance_msg = %(Changed attendance status from: "#{old_attendance}"
        to "#{new_attendance}".).squish
    end
    @message_to_organizer = args['organizer_message']

    @member = membership.person
    @event = membership.event
    @organizer = @event.organizer
    @organization = GetSetting.org_name(@event.location)

    from_email = GetSetting.email(location, 'maillist_from')
    reply_to = GetSetting.rsvp_email(@event.location)
    subject = '[' + @event.code + '] Membership invitation reply'

    to_email = '"' + @organizer.name + '" <' + @organizer.email + '>'
    if Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
      to_email = GetSetting.site_email('webmaster_email')
    end

    mail(to: to_email,
         from: from_email,
         subject: subject,
         return_path: reply_to) do |format|
      format.text { render text: '' }
    end
  end
end
