# app/forms/invitation_form.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Form at views/invitations/new.html.erb
class InvitationForm < ComplexForms
  attr_accessor :event, :email, :membership

  validate :selected_event
  validate :valid_email
  validate :is_member

  def initialize(attributes = {})
    @event = attributes['event']
    @email = attributes['email']
    @membership = nil
  end

  def selected_event
    if event.blank?
      errors.add(:event, ": You must select the event to which you were invited.")
    elsif event !~ /#{Setting.Site['code_pattern']}/
      errors.add(:event, ": Invalid event code.")
    else
      ev = Event.find(event)
      if ev.nil?
        errors.add(:event, ": No record of that event.")
      elsif ev.start_date < Time.zone.today
        errors.add(:event, ": Event is in the past.")
      end
    end
  end

  def valid_email
    if email.blank?
      errors.add(:email, ": Your e-mail address is required to confirm your invitation.")
    elsif !EmailValidator.valid?(email)
      errors.add(:email, ": You must enter a valid e-mail address.")
    end
  end

  def no_email_found
    errors.add(:email, ": We have no record of that email address.
      Is it possible that we were given a different email address for you?")
  end

  def no_membership
    errors.add(:email, ": that e-mail address is not associated to the
      event you selected. Do you have a different e-mail address that we
      might have in our records?")
  end

  def declined_already(event)
    errors.add(:Membership, ": You have already declined an invitation
      to this event. Please contact the event's organizers to ask if it
      is still possible to attend.
      The contact organizer is: <u>#{organizer(event)}</u>.<br />
      You may also contact the #{event.location} Program Coordinator
      at #{GetSetting.email(event.location, 'program_coordinator')}".squish)
  end

  def not_invited(event)
    errors.add(:Membership, ": The event's organizers have not yet
      invited you. Please contact them if you wish to be invited.<br />
      The contact organizer is: <u>#{organizer(event)}</u>.".squish)
  end

  def check_membership(event, person)
    @membership = Membership.where(person: person, event: event).first
    no_membership and return if @membership.nil?
    valid_membership?(@membership)
  end

  def valid_membership?(membership)
    if membership.attendance == 'Declined'
      declined_already(membership.event)
      return
    end
    not_invited(membership.event) if membership.attendance == 'Not Yet Invited'
  end

  def is_member
    return if errors.any?
    person = Person.find_by_email(email)
    no_email_found and return if person.nil?

    check_membership(Event.find(event), person)
    !errors.any?
  end

  def organizer(event)
    om = event.memberships.detect { |m| m.role == 'Contact Organizer' }
    link = ''
    if om.nil?
      event_url = Setting.Site['events_url'] + event.code
      link = '<a href="' + event_url + '">' + event_url + '</a>'
    else
      link = '<a href="mailto:'
      link += "'#{om.person.name}' <#{om.person.email}>"
      link += "?Subject=[#{event.code}] \">#{om.person.name}</a>".html_safe
    end
    link
  end
end
