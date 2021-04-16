# ./app/services/email_template_selector.rb
# Copyright (c) 2021 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Returns a hash of the email templates and paths appropriate
# for a given invitation object, for the invitation_mailer.
class EmailTemplateSelector
  attr_reader :membership, :template

  def initialize(invitation)
    @membership = invitation.membership
    @template = invitation.template
  end

  def set_format_template(template_name)
    if membership.event.online?
      template_name = "Virtual " + template_name
    end

    if membership.event.hybrid?
      template_name = "Hybrid " + template_name
    end

    template_name
  end

  def set_role_template(template_name)
    return template_name if membership.event.online?
    if membership.role.match?('Virtual')
      template_name = template_name + "-Virtual"
    elsif membership.role == 'Observer'
      template_name = template_name + "-Observer"
    end

    return template_name
  end

  def set_pdf_template(pdf_template_file)
    return 'not-applicable.pdf' if membership.event.online? ||
                                   membership.event.hybrid?
    return 'not-applicable.pdf' if membership.role.include?('Virtual') ||
                                   membership.role.include?('Observer')
    pdf_template_file
  end

  def set_template
    event = membership.event
    template_path = Rails.root.join('app', 'views', 'invitation_mailer',
                      "#{event.location}")
    basic_template_name = "#{event.event_type}-#{@template}"

    pdf_template_file = "#{template_path}/#{basic_template_name}.pdf.erb"
    pdf_template = "invitation_mailer/#{event.location}/
                                      #{basic_template_name}.pdf.erb".squish

    name_with_event_format = set_format_template(basic_template_name)
    final_template_name = set_role_template(name_with_event_format)
    pdf_template_file = set_pdf_template(pdf_template_file)

    text_template_file = "#{template_path}/#{final_template_name}.text.erb"
    relative_template_path = "invitation_mailer/#{event.location}"
    text_template = "#{relative_template_path}/#{final_template_name}.text.erb"

    invitation_file = "#{event.location}-invitation-#{membership.person_id}.pdf"

    {
           template_name: final_template_name,
           text_template: text_template,
      text_template_file: text_template_file,
           template_path: relative_template_path,
            pdf_template: pdf_template,
       pdf_template_file: pdf_template_file,
         invitation_file: invitation_file
    }
  end
end
