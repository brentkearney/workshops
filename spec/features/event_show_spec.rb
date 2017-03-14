# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Show Page', type: :feature do
  before do
    @event = create(:event_with_members)
    @member = @event.memberships.where("role='Participant'").first
    @user = create(:user, email: @member.person.email, person: @member.person)
    @non_member_user = create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def shows_partial_details
    expect(page.body).to have_css('h4.event-details', text: "Event Details")
    expect(page.body).to have_text(@event.code)
    expect(page.body).to have_text(@event.name)
    expect(page.body).to have_text(@event.location)
    expect(page.body).to have_text(@event.time_zone)
    expect(page.body).to have_text(@event.arrival_date)
    expect(page.body).to have_text(@event.departure_date)
    expect(page.body).to have_text(@event.event_type)
    expect(page.body).to have_link(@event.url)
    expect(page.body).to have_text(@event.description)
  end

  def shows_full_details
    shows_partial_details
    expect(page.body).to have_text(@event.short_name)
    expect(page.body).to have_text(@event.door_code)
    expect(page.body).to have_text(@event.max_participants)
    expect(page.body).to have_text(@event.booking_code)
  end

  def hides_some_details
    expect(page.body).not_to have_text(@event.door_code)
    expect(page.body).not_to have_text(@event.booking_code)
    expect(page.body).not_to have_text(@event.max_participants)
  end

  def has_no_edit_button
    expect(page.body).not_to have_link('Edit Event')
    expect(page.body).to have_link('Event Schedule')
  end

  def has_edit_button
    expect(page.body).to have_link('Edit Event')
  end

  def has_schedule_button
    expect(page.body).to have_link('Event Schedule')
  end

  def has_website_link(event)
    expect(page.body).to have_link('Event Website', :href => event.website)
  end

  context 'As a not-logged in user' do
    before do
      visit event_path(@event)
    end

    it 'shows partial event details' do
      shows_partial_details
    end

    it 'hides some details' do
      hides_some_details
    end

    it 'has no edit button' do
      has_no_edit_button
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit event_path(@event)
    end

    it 'shows partial event details' do
      shows_partial_details
    end

    it 'hides some details' do
      hides_some_details
    end

    it 'has no edit button' do
      has_no_edit_button
    end
  end

  context 'As a logged-in user who is a member of the event' do
    before do
      login_as @user, scope: :user
      visit event_path(@event)
    end

    it 'shows full event details' do
      shows_full_details
    end

    it 'has no edit button' do
      has_no_edit_button
    end
  end

  context 'As an organizer of the event' do
    before do
      @member.role = 'Organizer'
      @member.save!
      login_as @user, scope: :user
      visit event_path(@event)
    end

    it 'shows full event details' do
      shows_full_details
    end

    it 'has edit button' do
      has_edit_button
    end
  end

  context 'As a staff user' do
    before do
      @non_member_user.staff!
      login_as @non_member_user, scope: :user
    end

    context 'whose location matches the event location' do
      before do
        @non_member_user.location = @event.location
        @non_member_user.save!
        visit event_path(@event)
      end

      it 'shows full event details, including booking code' do
        shows_full_details
        expect(page.body).to have_text(@event.booking_code)
      end

      it 'has edit button' do
        has_edit_button
      end
    end

    context 'whose location does NOT match the event location' do
      before do
        @non_member_user.location = 'Somewhere else'
        @non_member_user.save!
        visit event_path(@event)
      end

      it 'shows partial event details' do
        shows_partial_details
        expect(page.body).not_to have_text(@event.booking_code)
      end

      it 'has no edit button' do
        has_no_edit_button
      end

      it 'has schedule button' do
        has_schedule_button
      end
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.admin!
      login_as @non_member_user, scope: :user
      visit event_path(@event)
    end

    it 'shows full event details, including booking code' do
      shows_full_details
      expect(page.body).to have_text(@event.booking_code)
    end

    it 'has edit button' do
      has_edit_button
    end
  end

end
