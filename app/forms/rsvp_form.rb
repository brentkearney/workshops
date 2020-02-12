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
    @person = @membership.person
    @person.is_rsvp = true
    @person.is_organizer_rsvp = true if @membership.role =~ /Organizer/

    @event = @membership.event
    self
  end

  def grant_list
    [
      ["1501 - Genes, Cells and Molecules", "NSERC:1501"],
      ["1502 - Biological Systems and Functions", "NSERC:1502"],
      ["1503 - Evolution and Ecology", "NSERC:1503"],
      ["1504 - Chemistry", "NSERC:1504"],
      ["1505 - Physics", "NSERC:1505"],
      ["1506 - Geosciences", "NSERC:1506"],
      ["1507 - Computer Science", "NSERC:1507"],
      ["1508 - Mathematics and Statistics", "NSERC:1508"],
      ["1509 - Civil, Industrial and Systems Engineering", "NSERC:1509"],
      ["1510 - Electrical and Computer Engineering", "NSERC:1510"],
      ["1511 - Materials and Chemical Engineering", "NSERC:1511"],
      ["1512 - Mechanical Engineering", "NSERC:1512"],
      ["CIHR grant", "CIHR"],
      ["SSHRC grant", "SSHRC"]
    ]
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
