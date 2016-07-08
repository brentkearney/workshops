# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Edit Page', type: :feature do
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

  def has_no_delete_button
    expect(page.body).not_to have_css('a', text: 'Delete This Event')
  end

  context 'Not logged-in' do
    it 'denies access' do
      visit edit_event_path(@event)
      expect(page.body).to have_css('div.alert.alert-alert.flash', text: 'You need to sign in or sign up before continuing.')
      expect(current_path).to eq(user_session_path)
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit edit_event_path(@event)
    end

    it 'denies access' do
      access_denied
      expect(current_path).to eq(my_events_path)
    end

  end

  context 'As a logged-in user who is a member of the event' do
    before do
      login_as @user, scope: :user
      visit edit_event_path(@event)
    end

    it 'denies access' do
      access_denied
      expect(current_path).to eq(my_events_path)
    end
  end

  context 'As an organizer of the event' do
    before do
      organizer = @event.memberships.where("role='Organizer'").first.person
      user = create(:user, email: organizer.email, person: organizer)
      login_as user, scope: :user
      @allowed_fields = %w(short_name description press_release)
      @not_allowed_fields = %w(name code door_code booking_code max_participants start_date end_date)
      visit edit_event_path(@event)
    end

    it 'allows access' do
      expect(current_path).to eq(edit_event_path(@event))
    end

    it 'has no Delete button' do
      has_no_delete_button
    end

    it 'excludes disallowed fields' do
      @not_allowed_fields.each do |field|
        expect(page.body).not_to have_field("event[#{field}]")
      end
    end

    it 'includes allowed fields' do
      @allowed_fields.each do |field|
        expect(page.body).to have_field("event[#{field}]")
      end
    end

    it 'updates the allowed fields' do
      @allowed_fields.each do |field|
        page.fill_in "event_#{field}", with: 'Some new text'
      end

      click_button 'Update Event'

      event = Event.find(@event.id)
      @allowed_fields.each do |field|
        expect(event.send(field)).to eq('Some new text')
      end
    end
  end

  context 'As a staff user' do
    before do
      @non_member_user.staff!
      login_as @non_member_user, scope: :user
      @allowed_fields = %w(short_name description press_release door_code booking_code)
      @not_allowed_fields = %w(name code max_participants start_date end_date time_zone location template)
    end

    context 'whose location matches the event location' do
      before do
        @non_member_user.location = @event.location
        @non_member_user.save!
        visit edit_event_path(@event)
      end

      it 'allows access' do
        expect(current_path).to eq(edit_event_path(@event))
      end

      it 'has no Delete button' do
        has_no_delete_button
      end

      it 'excludes disallowed fields' do
        @not_allowed_fields.each do |field|
          expect(page.body).not_to have_field("event[#{field}]")
        end
      end

      it 'includes allowed fields' do
        @allowed_fields.each do |field|
          expect(page.body).to have_field("event[#{field}]")
        end
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
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.admin!
      login_as @non_member_user, scope: :user
      @allowed_fields = %w(short_name description press_release door_code booking_code name code max_participants start_date end_date time_zone location)
      @not_allowed_fields = %w(id updated_by created_at updated_at confirmed_count publish_schedule)
      visit edit_event_path(@event)
    end

    it 'allows access' do
      expect(current_path).to eq(edit_event_path(@event))
    end

    it 'has no Delete button' do
      has_no_delete_button
    end

    it 'excludes disallowed fields' do
      @not_allowed_fields.each do |field|
        expect(page.body).not_to have_field("event[#{field}]")
      end
    end

    it 'includes allowed fields' do
      @allowed_fields.each do |field|
        expect(page.body).to have_field("event[#{field}]")
      end
    end
  end

  context 'As a super-admin user' do
    before do
      @non_member_user.super_admin!
      login_as @non_member_user, scope: :user
      visit edit_event_path(@event)
    end

    it 'allows access' do
      expect(current_path).to eq(edit_event_path(@event))
    end

    it 'has a Delete button' do
      expect(page.body).to have_css('a', text: 'Delete This Event')
    end
  end
end
