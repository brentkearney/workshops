# ./app/services/invitation_template_selector.rb
# Copyright (c) 2021 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Returns a hash of the email templates and paths appropriate
# for a given membership and template (attendance *before update*).
class InvitationTemplateSelector
  attr_reader :membership

  def initialize(membership)
    @membership = membership
  end

  def invitation_file
    "#{membership.event.location}-invitation-#{membership.person_id}.pdf"
  end

  def normal_template
    event = membership.event
    event.event_format + '-' + event.event_type + '-' + membership.attendance
  end

  def pdf_template_file
    return 'not-applicable' if virtual_event_or_observer?

    "#{template_path}/#{template_name}.pdf.erb"
  end

  def relative_template_path
    "invitation_mailer/#{membership.event.location}"
  end

  def template_name
    membership.role.match?('Virtual') ? virtual_template : normal_template
  end

  def template_path
    Rails.root.join('app', 'views', 'invitation_mailer',
        "#{membership.event.location}")
  end

  def text_template
    "#{relative_template_path}/#{template_name}.text.erb"
  end

  def text_template_file
    "#{template_path}/#{template_name}.text.erb"
  end

  def virtual_event_or_observer?
    membership.event.online? || membership.role.match?(/Virtual|Observer/)
  end

  def virtual_template
    template = normal_template
    template << '-Virtual' unless membership.event.online?
    template
  end

  def set_templates
    return { text_template_file: 'n/a' } if membership.attendance == 'Confirmed'
    {
      template_name:      template_name,
      text_template:      text_template,
      text_template_file: text_template_file,
      template_path:      relative_template_path,
      pdf_template_file:  pdf_template_file,
      invitation_file:    invitation_file
    }
  end
end
