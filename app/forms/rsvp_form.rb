# app/forms/rsvp_form.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/rsvp/index.html.erb
class RsvpForm < ComplexForms
  attr_accessor :membership, :person, :event, :invitation, :organizer_message,
                :grant_list

  def initialize(invitation)
    @invitation = invitation

    @membership = invitation.membership
    @event = @membership.event
    @person = @membership.person
    @person.is_rsvp = true
    @person.is_online_rsvp = true if @event.online?
    @person.is_organizer_rsvp = true if @membership.role.match?(/Organizer/)
    @grant_list = RsvpForm.grant_list
    self
  end

  def self.grant_list
    GetSetting.grant_list
  end

  def validate_form(attributes = {})
    @membership.assign_attributes(attributes['membership'])
    @person.assign_attributes(attributes['person'])

    unless @membership.valid? && @person.valid?
      @person.errors.full_messages.each do |key, value|
        errors.add(key, value)
      end

      @membership.errors.full_messages.each do |key, value|
        errors.add(key, value) unless key.match?(/^Person/)
      end
    end

    @membership.save! if @membership.valid?
  end

  def has_no_account?
    User.find_by_email(@person.email).nil?
  end

  def date_list
    dates = [@event.start_date]
    dates << dates.last + 1.day while dates.last != @event.end_date
    dates.collect {|d| [d.strftime("%A, %b %-d, %Y"), d] }
  end

  def arrival_departure_intro
    default = "If you plan to arrive after the event starts, or to leave before it ends, please indicate when by clicking the days on the calendars below. If you plan to book your own accommodation instead, please check the box below the calendars."
    (GetSetting.rsvp_dates_intro(@event.location) || default).html_safe
  end

  def accommodation_intro
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

  def biography_intro
    default = "An optional biographical summary for other participants to see."
    (GetSetting.rsvp_biography_intro(@event.location) || default).html_safe
  end

  def privacy_notice
    default = "Privacy Notice: We promise not to share your information with anyone."
    (GetSetting.rsvp_privacy_notice(@event.location) || default).html_safe
  end
end
