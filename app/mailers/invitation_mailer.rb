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

class InvitationMailer < MandrillMailer::TemplateMailer
  def compose_organizers(event)
    organizers = ''
    event.organizers.each do |org|
      organizers << org.name + ' (' + org.affiliation + '), '
    end
    organizers.gsub!(/, $/, '')
  end

  def set_format_template(membership, template_name)
    if membership.event.online?
      template_name = "Virtual " + template_name
    end

    if membership.event.hybrid?
      template_name = "Hybrid " + template_name
    end

    template_name
  end

  def set_role_template(membership, template_name)
    return template_name if membership.event.online?
    if membership.role.match?('Virtual')
      template_name = template_name + "-Virtual"
    elsif membership.role == 'Observer'
      template_name = template_name + "-Observer"
    end

    return template_name
  end

  def set_pdf_template(membership, pdf_template_file)
    return 'not-applicable.pdf' if membership.event.online? ||
                                   membership.event.hybrid?
    return 'not-applicable.pdf' if membership.role.include?('Virtual') ||
                                   membership.role.include?('Observer')
    pdf_template_file
  end

  def set_template(membership, attendance)
    event = membership.event
    template_path = Rails.root.join('app', 'views', 'invitation_mailer',
                      "#{event.location}")
    template_name = "#{event.event_type}-#{attendance}"

    pdf_template_file = "#{template_path}/#{template_name}.pdf.erb"
    pdf_template = "invitation_mailer/#{event.location}/#{template_name}.pdf.erb"

    template_name = set_format_template(membership, template_name)
    template_name = set_role_template(membership, template_name)
    pdf_template_file = set_pdf_template(membership, pdf_template_file)

    text_template_file = "#{template_path}/#{template_name}.text.erb"
    text_template = "invitation_mailer/#{event.location}/#{template_name}.text.erb"

    invitation_file = "#{event.location}-invitation-#{membership.person_id}.pdf"

    {
           template_name: template_name,
           text_template: text_template,
          template_label: event.location,
      text_template_file: text_template_file,
            pdf_template: pdf_template,
       pdf_template_file: pdf_template_file,
         invitation_file: invitation_file
    }
  end

  def invite(invitation, attendance)
    # attendance is pre-updated membership.attendance
    @membership = invitation.membership
    @person = @membership.person
    @event = @membership.event
    @rsvp_url = invitation.rsvp_url
    @invitation_date = invitation.invited_on.strftime('%A, %B %-d, %Y')
    Time.zone = @event.time_zone

    # no invitations to physical events once they've started
    return if @event.physical? && @event.start_date.in_time_zone < Time.now

    @event_start = @event.start_date.in_time_zone.strftime('%A, %B %-d')
    @event_end = @event.end_date.in_time_zone.strftime('%A, %B %-d, %Y')

    @rsvp_deadline = RsvpDeadline.new(@event).rsvp_by
    @organizers = compose_organizers(@event)

    from_email, from_name = GetSetting.rsvp_email(@event.location)

    location = @event.location
    subject = "#{location} Workshop Invitation: #{@event.name} (#{@event.code})"

    to_email = @person.email
    if Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
      to_email = GetSetting.site_email('webmaster_email')
    end

    # Set email template according to location, type of event, and attendance status
    templates = set_template(@membership, attendance)
    template_name = templates[:template_name].downcase.parameterize

    # Create PDF attachment
    # WickedPDF.render_to_string no longer works?
    attachments = []
    # if File.exist?(templates[:pdf_template_file])
    #   @page_title = "#{location} Invitation Details"
    #   pdf_file = WickedPdf.new.pdf_from_string(
    #     render_to_string(template: "#{templates[:pdf_template]}",
    #                      encoding: "UTF-8",
    #                    lowquality: false,
    #                     page_size: 'Letter'))

    #   # attachments[templates[:invitation_file]] = pdf_file
    #   attachments = [
    #     {
    #       content: pdf_file,
    #       name: templates[:invitation_file],
    #       type: application/pdf
    #     }
    #   ]

      ## save to a file (for testing)
      # save_path = Rails.root.join('tmp','invitation.pdf')
      # File.open(save_path, 'wb') do |file|
      #   file << pdf_file
      # end
    # end

    headers = {
          'X-BIRS-Sender': "#{invitation.invited_by}",
             'X-Priority': 1,
      'X-MSMail-Priority': 'High'
    }

    Rails.logger.debug "\n\n************************************************\n\n"
    Rails.logger.debug "Sending mandrill_mail with template: #{template_name}\n"
    Rails.logger.debug "sending to: <#{@person.name}> #{to_email}..."
    Rails.logger.debug "\n\n************************************************\n\n"

    mandrill_mail(
      template: template_name,
      from_email: from_email,
      from_name: from_name,
      subject: subject,
      to: [
        {
          email: to_email,
          name: @person.name,
          type: "to"
        },
        {
          email: from_email,
          type: "bcc"
        },
      ],
      vars: {
        dear_name: @person.dear_name,
        event_name: @event.name,
        event_code: @event.code,
        event_url: @event.url,
        event_start: @event_start,
        event_end: @event_end,
        rsvp_url: @rsvp_url,
        rsvp_deadline: @rsvp_deadline
      },
      headers: headers,
      merge_language: 'handlebars',
      merge: true,
      track_opens: false,
      track_clicks: false,
      attachments: attachments
    )
  end
end
