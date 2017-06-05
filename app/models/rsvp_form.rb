class RsvpForm < ComplexForms
  # For views/rsvp/index.html.erb
  attr_accessor :membership, :person, :event, :invitation, :organizer_message

  def initialize(invitation)
    @invitation = invitation

    @membership = invitation.membership
    @person = @membership.person
    @person.is_rsvp = true
    @event = @membership.event
    self
  end

  def validate_form(attributes = {})
    @membership.assign_attributes(attributes['membership'])
    @person.assign_attributes(attributes['person'])

    unless @membership.valid?
      @membership.errors.full_messages.each do |key, value|
        errors.add(key, value)
      end
    end

    @membership.save! if @membership.valid?
  end

  def arrival_departure_intro
    default = "If you plan to arrive after the event starts, or to leave before it ends, please indicate when by clicking the days on the calendars below. If you plan to book your own accommodation instead, please check the box below the calendars."

    (Setting.RSVP["#{@event.location}"]['arrival_departure_intro'] || default).html_safe
  end

  def guests_intro
    default = "If you wish to bring a guest, please select the checkbox below."
    (Setting.RSVP["#{@event.location}"]['guests_intro'] || default).html_safe
  end

  def has_guest
    default = "I plan to bring a guest with me."
    (Setting.RSVP["#{@event.location}"]['has_guest'] || default).html_safe
  end

  def guest_disclaimer
    default = "I am aware that I may have to pay extra for my guest's accommodation."
    (Setting.RSVP["#{@event.location}"]['guest_disclaimer']).html_safe
  end

  def special_intro
    default = "Please let us know if you have any special dietary or other needs."
    (Setting.RSVP["#{@event.location}"]['special_intro'] || default).html_safe
  end

  def personal_info_intro
    default = ""
    (Setting.RSVP["#{@event.location}"]['personal_info_intro'] || default).html_safe
  end

  def privacy_notice
    default = "We promise not to share your information with anyone."
    (Setting.RSVP["#{@event.location}"]['privacy_notice'] || default).html_safe
  end
end
