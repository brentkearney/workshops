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
  def compose_organizers(event)
    organizers = ''
    event.organizers.each do |org|
      organizers << org.name + ' (' + org.affiliation + '), '
    end
    organizers.gsub!(/, $/, '')
  end

  def set_template(membership, template)
    event = membership.event
    template_path = Rails.root.join('app', 'views', 'invitation_mailer',
                      "#{event.location}")
    template_name = "#{event.event_type}-#{template}"

    pdf_template_file = "#{template_path}/#{template_name}.pdf.erb"
    pdf_template = "invitation_mailer/#{event.location}/#{template_name}.pdf.erb"

    if event.online?
      template_name = "Virtual " + template_name
      pdf_template_file = 'not_applicable.pdf'
    end

    if event.hybrid?
      template_name = "Hybrid " + template_name
      pdf_template_file = 'not_applicable.pdf'
    end

    text_template_file = "#{template_path}/#{template_name}.text.erb"
    text_template = "invitation_mailer/#{event.location}/#{template_name}.text.erb"

    if membership.role == 'Observer'
      text_template_file.gsub!(/\.text/, "-Observer\.text")
      text_template.gsub!(/\.text/, "-Observer\.text")
      pdf_template_file = 'no-file'
    end

    invitation_file = "#{event.location}-invitation-#{membership.person_id}.pdf"

    {
           template_name: template_name,
           text_template: text_template,
      text_template_file: text_template_file,
            pdf_template: pdf_template,
       pdf_template_file: pdf_template_file,
         invitation_file: invitation_file
    }
  end

  def invite(invitation, template)
    @person = invitation.membership.person
    @event = invitation.membership.event
    @membership = invitation.membership
    @rsvp_url = invitation.rsvp_url
    @invitation_date = invitation.invited_on.strftime('%A, %B %-d, %Y')

    Time.zone = @event.time_zone

    # no invitations to physical events once they've started
    return if @event.physical? && @event.start_date.in_time_zone < Time.now

    @event_start = @event.start_date.in_time_zone.strftime('%A, %B %-d')
    @event_end = @event.end_date.in_time_zone.strftime('%A, %B %-d, %Y')

    @rsvp_deadline = RsvpDeadline.new(@event).rsvp_by
    @organizers = compose_organizers(@event)

    from_email = GetSetting.rsvp_email(@event.location)

    location = @event.location
    subject = "#{location} Workshop Invitation: #{@event.name} (#{@event.code})"

    bcc_email = GetSetting.rsvp_email(@event.location)
    bcc_email = bcc_email.match(/<(.+)>/)[1] if bcc_email.match?(/</)
    to_email = '"' + @person.name + '" <' + @person.email + '>'

    if Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
      to_email = GetSetting.site_email('webmaster_email')
    end

    # Set email template according to location, type of event, and attendance status
    templates = set_template(@membership, template)

    # Create PDF attachment
    if File.exist?(templates[:pdf_template_file])
      @page_title = "#{location} Invitation Details"
      pdf_file = WickedPdf.new.pdf_from_string(
        render_to_string(template: "#{templates[:pdf_template]}",
                         encoding: "UTF-8",
                       lowquality: false,
                        page_size: 'Letter'))

      attachments[templates[:invitation_file]] = pdf_file

      ## save to a file (for testing)
      # save_path = Rails.root.join('tmp','invitation.pdf')
      # File.open(save_path, 'wb') do |file|
      #   file << pdf_file
      # end
    end

    headers['X-BIRS-Sender'] = "#{invitation.invited_by}"
    headers['X-Priority'] = 1
    headers['X-MSMail-Priority'] = 'High'

    if File.exist?(templates[:text_template_file])
      mail(to: to_email,
           bcc: bcc_email,
           from: from_email,
           subject: subject,
           template_path: "invitation_mailer/#{@event.location}",
           template_name: templates[:template_name]) do |format|
        format.text { render templates[:text_template] }
      end
    else
      error_msg = { problem: 'Participant (re)invitation not sent.',
                    cause: 'Email template file missing.',
                    template: templates[:text_template_file],
                    person: @person,
                    membership: @membership,
                    invitation: invitation }
      StaffMailer.notify_sysadmin(@event, error_msg).deliver_now
    end
  end
end
