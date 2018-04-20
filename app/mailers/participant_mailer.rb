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

class ParticipantMailer < ApplicationMailer
  self.delivery_method = :sparkpost if Rails.env.production?

  def rsvp_confirmation(membership)
    @person = membership.person
    @event = membership.event
    @organization = GetSetting.org_name(@event.location)

    # PDF attachment in lib/assets/rsvp/[location]
    pdf_path = Rails.root.join('lib', 'assets', 'rsvp', "#{@event.location}")
    file_attachment = "#{pdf_path}/#{@event.event_type}.pdf"
    if File.exist?("#{file_attachment}") # spaces in file name
      attachments["#{@event.location}-arrival-info.pdf"] = {
        mime_type: 'application/pdf',
        content: File.read(file_attachment)
      }
    end

    from_email = GetSetting.email(@event.location, 'rsvp')
    subject = "[#{@event.code}] Thank you for accepting our invitation"
    to_email = '"' + @person.name + '" <' + @person.email + '>'
    if Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
      to_email = GetSetting.site_email('webmaster_email')
    end

    template_path = Rails.root.join('app', 'views', 'participant_mailer',
                      'rsvp', "#{@event.location}")
    mail_template = "#{template_path}/#{@event.event_type}.text.erb"
    if File.exist?(mail_template)
      mail(to: to_email,
           from: from_email,
           subject: subject,
           template_path: "participant_mailer/rsvp/#{@event.location}",
           template_name: @event.event_type)
    else
      error_msg = { problem: 'Participant RSVP confirmation not sent.',
                    cause: 'Email template file missing.',
                    template: mail_template,
                    person: @person,
                    membership: membership }
      StaffMailer.notify_sysadmin(@event, error_msg).deliver_now
    end
  end
end
