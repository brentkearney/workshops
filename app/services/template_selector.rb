class TemplateSelector
  attr_accessor :membership, :template

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
    template_name = "#{event.event_type}-#{template}"

    pdf_template_file = "#{template_path}/#{template_name}.pdf.erb"
    pdf_template = "invitation_mailer/#{event.location}/#{template_name}.pdf.erb"

    template_name = set_format_template(template_name)
    template_name = set_role_template(template_name)
    pdf_template_file = set_pdf_template(pdf_template_file)

    text_template_file = "#{template_path}/#{template_name}.text.erb"
    relative_template_path = "invitation_mailer/#{event.location}"
    text_template = "#{relative_template_path}/#{template_name}.text.erb"

    invitation_file = "#{event.location}-invitation-#{membership.person_id}.pdf"

    {
           template_name: template_name,
           text_template: text_template,
      text_template_file: text_template_file,
           template_path: relative_template_path,
            pdf_template: pdf_template,
       pdf_template_file: pdf_template_file,
         invitation_file: invitation_file
    }
  end
end
