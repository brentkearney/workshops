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

class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @person = invitation.membership.person
    @event = invitation.membership.event
    @membership = invitation.membership
    @rsvp_url = invitation.rsvp_url

    return if @event.start_date.to_time.to_i < Time.now.to_i
    @event_start = @event.start_date.to_time.strftime('%A, %B %-d')
    @event_end = @event.end_date.to_time.strftime('%A, %B %-d, %Y')

    @rsvp_deadline = RsvpDeadline.new(@event.start_date).rsvp_by

    @organizers = ''
    @event.organizers.each do |org|
      @organizers << org.name + ' (' + org.affiliation + '), '
    end
    @organizers.gsub!(/, $/, '')

    from_email = GetSetting.rsvp_email(@event.location)
    subject = "#{@event.location} Workshop Invitation: #{@event.name} (#{@event.code})"
    bcc_email = GetSetting.rsvp_email(@event.location)
    bcc_email = bcc_email.match(/<(.+)>/)[1] if bcc_email =~ /</
    to_email = '"' + @person.name + '" <' + @person.email + '>'

    if Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
      to_email = GetSetting.site_email('webmaster_email')
    end

    template_path = Rails.root.join('app', 'views', 'invitation_mailer',
                      "#{@event.location}")
    pdf_template_file = "#{template_path}/#{@event.event_type}.pdf.erb"
    pdf_template = "invitation_mailer/#{@event.location}/#{@event.event_type}.pdf.erb"
    text_template_file = "#{template_path}/#{@event.event_type}.text.erb"
    text_template = "invitation_mailer/#{@event.location}/#{@event.event_type}.text.erb"

    if @membership.role == 'Observer'
      text_template_file.gsub!(/\.text/, "-Observer\.text")
      text_template.gsub!(/\.text/, "-Observer\.text")
      pdf_template_file = 'no-file'
    end

    # Create PDF attachment
    if File.exist?(pdf_template_file)
      @page_title = "#{@event.location} Invitation Details"
      pdf_file = WickedPdf.new.pdf_from_string(
        render_to_string(template: "#{pdf_template}", encoding: "UTF-8",
          lowquality: false, page_size: 'Letter'))
      attachments["#{@event.location}-invitation-#{@person.id}.pdf"] = pdf_file

      ## save to a file (for testing)
      # save_path = Rails.root.join('tmp','invitation.pdf')
      # File.open(save_path, 'wb') do |file|
      #   file << pdf_file
      # end
    end

    if File.exist?(text_template_file)
      mail(to: to_email,
           bcc: bcc_email,
           from: from_email,
           subject: subject,
           template_path: "invitation_mailer/#{@event.location}",
           template_name: @event.event_type) do |format|
        format.text { render text_template }
      end
    else
      error_msg = { problem: 'Participant invitation not sent.',
                    cause: 'Email template file missing.',
                    template: text_template_file,
                    person: @person,
                    membership: @membership,
                    invitation: invitation }
      StaffMailer.notify_sysadmin(@event, error_msg).deliver_now
    end
  end
end
