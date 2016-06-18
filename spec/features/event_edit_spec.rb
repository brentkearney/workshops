# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Edit Page', :type => :feature do
  before do
    @event = create(:event_with_members)
    @member = @event.memberships.where("role='Participant'").first
    @user = create(:user, email: @member.person.email, person: @member.person)
    @non_member_user = create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def access_denied
    expect(page.body).to have_css('div.alert.alert-error.flash', text: 'Access denied.')
    expect(page.body).not_to include(@event.description)
  end

  def has_edit_button
    visit event_path(@event)
    expect(page.body).to have_css('a', text: 'Edit Event')
  end

  def has_no_edit_button
    visit event_path(@event)
    expect(page.body).not_to have_css('a', text: 'Edit Event')
  end

  def has_no_delete_button
    expect(page.body).not_to have_css('a', text: 'Delete This Event')
  end

  context 'Not logged-in' do
    it 'denies access' do
      visit edit_event_path(@event)
      expect(page.body).to have_css('div.alert.alert-alert.flash', text: 'You need to sign in or sign up before continuing.')
      expect(current_path).to eq(user_session_path)
    end

    it '#show does not have an Edit Event button' do
      has_no_edit_button
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit edit_event_path(@event)
    end

    it 'denies access' do
      access_denied
    end

    it '#show does not have an Edit Event button' do
      has_no_edit_button
    end
  end

  context 'As a logged-in user who is a member of the event' do
    before do
      login_as @user, scope: :user
      visit edit_event_path(@event)
    end

    it 'denies access' do
      access_denied
    end

    it '#show does not have an Edit Event button' do
      has_no_edit_button
    end
  end

  context 'As an organizer of the event' do
    before do
      organizer = @event.memberships.where("role='Organizer'").first.person
      user = create(:user, email: organizer.email, person: organizer)
      login_as user, scope: :user
      visit edit_event_path(@event)
    end

    it 'has no Delete button' do
      has_no_delete_button
    end

    it 'excludes: code, door_code, booking_code, max_participants, name, dates, press_release' do
      expect(page.body).not_to have_css('input#event_code')
      expect(page.body).not_to have_css('input#event_door_code')
      expect(page.body).not_to have_css('input#event_booking_code')
      expect(page.body).not_to have_css('input#event_max_participants')
      expect(page.body).not_to have_css('textarea#event_name')
      expect(page.body).not_to have_css('input#start_date')
      expect(page.body).not_to have_css('input#end_date')
      expect(page.body).not_to have_css('textarea#event_press_release')
    end

    it '#show has an Edit Event button' do
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
        visit edit_event_path(@event)
      end

      it 'has no Delete button' do
        has_no_delete_button
      end

      it 'allows editing'
      it 'denies editing some details'

      it '#show has an Edit Event button' do
        has_edit_button
      end
    end

    context 'whose location does NOT match the event location' do
      before do
        @non_member_user.location = 'Somewhere else'
        @non_member_user.save!
        visit edit_event_path(@event)
      end

      it 'denies access' do
        access_denied
      end

      it '#show does not have an Edit Event button' do
        has_no_edit_button
      end
    end
  end

end
