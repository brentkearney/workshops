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

# Email notices for the workshop organizer
class OrganizerMailer < ApplicationMailer
  def rsvp_notice(membership, args)
    old_attendance = args['attendance_was'] || 'Invited'
    new_attendance = args['attendance'] || 'Invited'
    if old_attendance == new_attendance
      @attendance_msg = "Attendance status is: #{new_attendance}."
    else
      @attendance_msg = %(Changed attendance status from: "#{old_attendance}"
        to "#{new_attendance}".).squish
    end
    message_to_organizer = args['organizer_message'] || ''

    member = membership.person
    event = membership.event
    organizer = event.organizer
    organization = GetSetting.org_name(event.location)

    from_email = GetSetting.site_email('application_email')
    reply_to = GetSetting.rsvp_email(event.location)
    subject = '[' + event.code + '] Membership invitation reply'

    to_email = '"' + organizer.name + '" <' + organizer.email + '>'
    if Rails.env.development? || request.original_url =~ /staging/
      to_email = GetSetting.site_email('webmaster_email')
    end

    sub_data = {
      person_name: "#{organizer.dear_name}",
      event_code: "#{event.code}",
      event_name: "#{event.name}",
      event_dates: "#{event.dates(:long)}",
      member_name: "#{member.name}",
      member_firstname: "#{member.firstname}",
      member_email: "#{member.email}",
      member_affiliation: "#{member.affiliation}",
      attendance_msg: "#{@attendance_msg}",
      message_to_organizer: "#{message_to_organizer}",
      organization: "#{organization}"
    }

    data = {
      template_id: 'rsvp-notice',
      substitution_data: sub_data
    }

    # to: email,
    mail(to: to_email,
         from: from_email,
         subject: subject,
         return_path: reply_to,
         delivery_method: :sparkpost,
         sparkpost_data: data) do |format|
      format.text { render text: '' }
    end
  end
end
