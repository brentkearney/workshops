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

class InvitationMailer < ApplicationMailer
  self.delivery_method = :sparkpost if Rails.env.production?

  def invite(invitation)
    @person = invitation.membership.person
    @event = invitation.membership.event
    @from_email = GetSetting.rsvp_email(@event.location)
    @bcc_email = GetSetting.rsvp_email(@event.location)
    @bcc_email = ''
    @subject = "[#{@event.code}] Workshop Invitation: #{@event.name}"

    @rsvp_link = GetSetting.app_url + '/rsvp/' + invitation.code
    @organizers = ''
    @event.organizers.each do |org|
      @organizers << org.name + ' (' + org.affiliation + '), '
    end
    @organizers.gsub!(/, $/, '')

    sub_data = {
      person_name: "#{@person.dear_name}",
      event_code: "#{@event.code}",
      event_name: "#{@event.name}",
      event_dates: "#{@event.dates(:long)}",
      event_url: "#{@event.url}",
      organizers: "#{@organizers}",
      rsvp_link: "#{@rsvp_link}"
    }

    data = {
      template_id: "#{@event.location.downcase}-participant-invitation",
      substitution_data: sub_data
    }

    mail(to: @person.email,
         from: @from_email,
         bcc: @bcc_email,
         subject: @subject,
         sparkpost_data: data) do |format|
      format.text { render text: '' }
    end
  end
end
