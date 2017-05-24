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
  @from_email = ENV['DEVISE_EMAIL']
  default from: @from_email

  def rsvp_confirmation(membership)
    @person = membership.person
    @event = membership.event
    unless Setting.Emails.blank?
      @from_email = Setting.Emails["#{@event.location}"]['rsvp']
    end

    @organization = 'Staff'
    unless Setting.Locations["#{membership.event.location}"].nil?
      @organization = Setting.Locations["#{membership.event.location}"]['Name']
    end

    template_path = "participant_mailer/rsvp/#{@event.location}"
    file_attachment = "#{template_path}/#{@event.event_type}.pdf"
    if File.exist?(file_attachment)
      attachments["#{@event.location}-arrival-info.pdf"] =
        File.read(file_attachment)
    end

    mail_template = "#{template_path}/#{@event.event_type}.text.erb"
    if File.exist?(mail_template)
      email = '"' + @person.name + '" <' + @person.email + '>'
      subject = "[#{@event.code}] Thank you for accepting our invitation"
      mail(to: email,
           from: @from_email,
           subject: subject,
           template_path: template_path,
           template_name: @event.event_type,
           attachments: attachments,
           'Importance': 'High', 'X-Priority': 1)
    end
  end
end
