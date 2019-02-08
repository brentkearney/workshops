# app/forms/rsvp_form.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/rsvp/index.html.erb
class RsvpForm < ComplexForms
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

  def date_list
    dates = [@event.start_date]
    dates << dates.last + 1.day while dates.last != @event.end_date
    dates
  end

  def arrival_departure_intro
    default = "If you plan to arrive after the event starts, or to leave before it ends, please indicate when by clicking the days on the calendars below. If you plan to book your own accommodation instead, please check the box below the calendars."
    (GetSetting.rsvp_dates_intro(@event.location) || default).html_safe
  end

  def accommodation_intro
    # default = "BIRS will book a free hotel room for you, <strong>unless you select the "I will book my own accommodation" option.</strong> If you select that option, you must book your own accommodation and pay for it."
    default = 'We will book free accommodation for you, unless you select the option to arrange & pay for your own accommodation'
    (GetSetting.rsvp_accommodation_intro(@event.location) || default).html_safe
  end

  def guests_intro
    default = "If you wish to bring a guest, please select the checkbox below."
    (GetSetting.rsvp_guests_intro(@event.location) || default).html_safe
  end

  def has_guest
    default = "I plan to bring a guest with me."
    (GetSetting.rsvp_has_guest(@event.location) || default).html_safe
  end

  def guest_disclaimer
    default = "I am aware that I may have to pay extra for my guest's accommodation."
    (GetSetting.rsvp_guest_disclaimer(@event.location) || default).html_safe
  end

  def special_intro
    default = "Please let us know if you have any special dietary or other needs."
    (GetSetting.rsvp_special_intro(@event.location) || default).html_safe
  end

  def personal_info_intro
    default = ""
    (GetSetting.rsvp_personal_info_intro(@event.location) || default).html_safe
  end

  def privacy_notice
    default = "Privacy Notice: We promise not to share your information with anyone."
    (GetSetting.rsvp_privacy_notice(@event.location) || default).html_safe
  end
end
