class EmailRecipients
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
