# ./app/services/invitation_template_selector.rb
# Copyright (c) 2021 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Returns a hash of the email templates and paths appropriate
# for a given membership and template (attendance before update).
class InvitationTemplateSelector
  attr_reader :membership, :template

  def initialize(membership, template)
    @membership = membership
    @template = template
  end

  def virtual_event_or_observer?
    membership.event.online? || membership.role.match?(/Virtual|Observer/)
  end

  def construct_pdf_template_name(template_path, template_name)
    template_name = 'not-applicable' if virtual_event_or_observer?

    "#{template_path}/#{template_name}.pdf.erb"
  end

  def construct_template_path(location)
    Rails.root.join('app', 'views', 'invitation_mailer', "#{location}")
  end

  def construct_template_name(event)
    event.event_format + '-' + event.event_type + '-' + template
  end

  def set_template
    event = membership.event
    template_path = construct_template_path(event.location)
    template_name = construct_template_name(event)

    pdf_template_file = construct_pdf_template_name(template_path,
                                                    template_name)
    invitation_file = "#{event.location}-invitation-#{membership.person_id}.pdf"

    text_template_file = "#{template_path}/#{template_name}.text.erb"
    relative_template_path = "invitation_mailer/#{event.location}"
    text_template = "#{relative_template_path}/#{template_name}.text.erb"

    {
           template_name: template_name,
           text_template: text_template,
      text_template_file: text_template_file,
           template_path: relative_template_path,
       pdf_template_file: pdf_template_file,
         invitation_file: invitation_file
    }
  end
end
