# Copyright (c) 2019 Banff International Research Station
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

class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @person = invitation.membership.person
    @event = invitation.membership.event
    @rsvp_url = invitation.rsvp_url
    @invitation_date = invitation.invited_on.strftime('%A, %B %-d, %Y')
    @event_start = @event.start_date_formatted
    @event_end = @event.end_date_formatted
    @rsvp_deadline = RsvpDeadline.new(@event).rsvp_by
    @organizers = PersonWithAffilList.compose(@event.organizers)

    location = @event.location
    subject = "#{location} Workshop Invitation: #{@event.name} (#{@event.code})"

    recipients = EmailRecipients.new(invitation).compose
    templates = EmailTemplateSelector.new(invitation).set_template

    # Create PDF attachment
    if File.exist?(templates[:pdf_template_file])
      generator = PdfTemplateGenerator.new(location, templates[:pdf_template])
      attachments[templates[:invitation_file]] = generator.pdf_file
    end

    headers['X-BIRS-Sender'] = "#{invitation.invited_by}"
    headers['X-BIRS-Event'] = "#{invitation.event.code}"
    headers['X-Priority'] = 1
    headers['X-MSMail-Priority'] = 'High'

    if File.exist?(templates[:text_template_file])
      mail(to: recipients[:to],
           bcc: recipients[:bcc],
           from: recipients[:from],
           subject: subject,
           template_path: templates[:template_path],
           template_name: templates[:template_name]) do |format|
        format.text { render templates[:text_template] }
      end
    else
      error_msg = { problem: 'Participant (re)invitation not sent.',
                    cause: 'Email template file missing.',
                    template: templates[:text_template_file],
                    recipients: recipients,
                    person: invitation.person,
                    membership: invitation.membership,
                    invitation: invitation }
      StaffMailer.notify_sysadmin(@event, error_msg).deliver_now
    end
  end
end
