# ./app/services/invitation_email_recipients.rb
# Copyright (c) 2021 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class InvitationEmailRecipients
  def initialize(invitation)
    @invitation = invitation
  end

  def compose
    from_email = GetSetting.rsvp_email(@invitation.event.location)

    person = @invitation.person
    to_email = '"' + person.name + '" <' + person.email + '>'

    bcc_email = GetSetting.rsvp_email(@invitation.event.location)
    bcc_email = bcc_email.match(/<(.+)>/)[1] if bcc_email.match?(/</)

    if Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
      to_email = GetSetting.site_email('webmaster_email')
    end

    {
      from: from_email,
      to: to_email,
      bcc: bcc_email
    }
  end
end
