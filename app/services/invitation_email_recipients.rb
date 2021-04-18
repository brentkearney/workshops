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

  def test_env?
    Rails.env.development? || ENV['APPLICATION_HOST'].include?('staging')
  end

  def webmaster_email
    GetSetting.site_email('webmaster_email')
  end

  def to_email
    return webmaster_email if test_env?
    '"' + @invitation.person.name + '" <' + @invitation.person.email + '>'
  end

  def from_email
    GetSetting.rsvp_email(@invitation.event.location)
  end

  def bcc_email
    email = from_email
    email = email.match(/<(.+)>/)[1] if email.match?(/</)
    email
  end

  def compose
    {
      from: from_email,
      to: to_email,
      bcc: bcc_email
    }
  end
end
