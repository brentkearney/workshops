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
    expect(page.body).to have_css('div.alert', text: 'Access denied.')
    expect(page.body).not_to include(@event.description)
  end

  def has_no_delete_button
    expect(page.body).not_to have_css('a', text: 'Delete This Event')
  end

  def has_delete_button
    expect(page.body).to have_css('a', text: 'Delete This Event')
  end

  context 'Not logged-in' do
    it 'denies access' do
      visit edit_event_path(@event)
      expect(page.body).to have_css('div.alert', text: 'You need to sign in or sign up before continuing.')
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
      @allowed_fields = %w(short_name description press_release subjects)
      @not_allowed_fields = %w(name code door_code booking_code max_participants
        max_virtual max_observers start_date end_date)
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
      @allowed_fields = %w(short_name description press_release door_code
        booking_code subjects max_participants max_virtual max_observers)
      @not_allowed_fields = %w(name code start_date end_date time_zone
        location template)
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

      it 'updates fields when submitted' do
        fill_in 'event_short_name', with: 'New Short Name'
        fill_in 'event_description', with: 'New Description'
        fill_in 'event_press_release', with: 'New Press Release'
        fill_in 'event_door_code', with: '6666'
        fill_in 'event_booking_code', with: 'NewCode'
        fill_in 'event_subjects', with: 'New Subjects'
        fill_in 'event_event_format', with: 'Hybrid'
        fill_in 'event_max_participants', with: '50'
        fill_in 'event_max_observers', with: '1'
        fill_in 'event_max_virtual', with: '100'
        fill_in 'event_cancelled', with: '1'

        click_button "Update Event"

        event = Event.find(@event.code)
        expect(event.short_name).to eq('New Short Name')
        expect(event.description).to eq('New Description')
        expect(event.press_release).to eq('New Press Release')
        expect(event.door_code).to eq(6666)
        expect(event.booking_code).to eq('NewCode')
        expect(event.subjects).to eq('New Subjects')
        expect(event.max_participants).to eq(50)
        expect(event.max_observers).to eq(1)
        expect(event.max_virtual).to eq(100)
        expect(event.cancelled).to be_truthy
        expect(event.event_format).to eq('Hybrid')
      end

      it 'appends "(Cancelled)" to event name when it is marked as cancelled' do
        expect(@event.name.include?('Cancelled')).to be_falsey
        fill_in 'event_cancelled', with: '1'

        click_button "Update Event"

        event = Event.find(@event.code)
        expect(event.name.include?('Cancelled')).to be_truthy
      end

      it 'removes "(Cancelled)" from event name when unmarked as cancelled' do
        @event.cancelled = true
        @event.save
        expect(@event.name.include?('Cancelled')).to be_truthy

        visit edit_event_path(@event)
        fill_in 'event_cancelled', with: '0'
        click_button "Update Event"

        event = Event.find(@event.code)
        expect(event.name.include?('Cancelled')).to be_falsey
      end

      it 'appends "(Online)" to event name when it is marked as online' do
        @event.update_columns(name: @event.name.tr(' (Online)', ''))
        expect(Event.find(@event.code).name.include?('Online')).to be_falsey

        fill_in 'event_event_format', with: 'Online'
        click_button "Update Event"

        event = Event.find(@event.code)
        expect(event.name.include?('Online')).to be_truthy
      end

      it 'removes "(Online)" from event name when unmarked as online' do
        @event.event_format = 'Online'
        @event.save
        expect(@event.name.include?('Online')).to be_truthy

        visit edit_event_path(@event)
        fill_in 'event_event_format', with: 'Physical'
        click_button "Update Event"

        event = Event.find(@event.code)
        expect(event.name.include?('Online')).to be_falsey
      end

      context "Updating the event_format" do

        def sets_max_virtual_to_default
          fill_in 'event_max_virtual', with: 0
          click_button "Update Event"

          default = GetSetting.max_virtual(@event.location)

          notice_text = "Changed Maximum Virtual Participants to #{default}."
          expect(page.body).to have_css('div.alert-notice', text: notice_text)

          event = Event.find(@event.code)
          expect(event.max_virtual).to eq(default)
        end

        def sets_max_participants_to_default
          fill_in 'event_max_participants', with: 0
          click_button "Update Event"

          default = GetSetting.max_participants(@event.location)

          notice_text = "Changed Maximum Participants to #{default}."
          expect(page.body).to have_css('div.alert-notice', text: notice_text)

          event = Event.find(@event.code)
          expect(event.max_participants).to eq(default)
        end

        def sets_max_participants_to_zero
          click_button "Update Event"

          event = Event.find(@event.code)
          expect(event.max_participants).to eq(0)
        end

        def sets_to_user_entered(field, value)
          fill_in "event_#{field}", with: value
          click_button "Update Event"

          event = Event.find(@event.code)
          expect(event.send(field)).to eq(value)
        end

        context "from Physical to Hybrid" do
          before do
            @event.update_columns(event_format: 'Physical',
                              max_participants: 50,
                              max_virtual: 0)

            visit edit_event_path(@event)
            fill_in 'event_event_format', with: 'Hybrid'
          end

          it 'does not change max_participants if no change submitted' do
            click_button "Update Event"
            event = Event.find(@event.code)
            expect(event.max_participants).to eq(50)
          end

          it 'sets max_virtual to what user entered' do
            sets_to_user_entered('max_virtual', 100)
          end

          it 'sets max_virtual to default value if 0 is submitted' do
            sets_max_virtual_to_default
          end

          it 'sets max_participants to default value if 0 submitted' do
            sets_max_participants_to_default
          end
        end

        context "from Physical to Online" do
          before do
            @event.update_columns(event_format: 'Physical',
                              max_participants: 50,
                              max_virtual: 0)

            visit edit_event_path(@event)
            fill_in 'event_event_format', with: 'Online'
          end

          it 'sets max_participants to 0' do
            sets_max_participants_to_zero
          end

          it 'sets max_virtual to default value if 0 submitted' do
            sets_max_virtual_to_default
          end

          it 'sets max_virtual non-zero value submitted' do
            sets_to_user_entered('max_virtual', 150)
          end
        end

        context "from Online to Physical" do
          before do
            @event.update_columns(event_format: 'Online',
                              max_participants: 0,
                              max_virtual: 100)

            visit edit_event_path(@event)
            fill_in 'event_event_format', with: 'Physical'
          end

          it "sets max_participants to default value if 0 submitted" do
            sets_max_participants_to_default
          end

          it 'sets max_participants non-zero value submitted' do
            sets_to_user_entered('max_participants', 55)
          end

          it 'sets max_virtual to 0' do
            click_button "Update Event"
            event = Event.find(@event.code)
            expect(event.max_virtual).to eq(0)
          end
        end

        context "from Online to Hybrid" do
          before do
            @event.update_columns(event_format: 'Online',
                              max_participants: 0,
                                   max_virtual: 100)

            visit edit_event_path(@event)
            fill_in 'event_event_format', with: 'Hybrid'
          end

          it 'does not change max_virtual if no change submitted' do
            click_button "Update Event"
            event = Event.find(@event.code)
            expect(event.max_virtual).to eq(100)
          end

          it 'sets max_virtual to what user entered' do
            sets_to_user_entered('max_virtual', 50)
          end

          it 'sets max_virtual to default value if 0 is submitted' do
            sets_max_virtual_to_default
          end

          it 'sets max_participants to default value if 0 submitted' do
            sets_max_participants_to_default
          end

          it 'sets max_participants to what user submits' do
            sets_to_user_entered('max_participants', 35)
          end
        end

        context "from Hybrid to Online" do
          before do
            @event.update_columns(event_format: 'Hybrid',
                              max_participants: 40,
                                   max_virtual: 50)

            visit edit_event_path(@event)
            fill_in 'event_event_format', with: 'Online'
          end

          it 'sets max_participants to 0' do
            sets_max_participants_to_zero
          end

          it 'does not change max_virtual' do
            click_button "Update Event"
            event = Event.find(@event.code)
            expect(event.max_virtual).to eq(50)
          end

          it 'sets max_virtual to value submitted' do
            sets_to_user_entered('max_virtual', 100)
          end

          it 'sets max_virtual to default value if 0 submitted' do
            sets_max_virtual_to_default
          end
        end

        context "from Hybrid to Physical" do
          before do
            @event.update_columns(event_format: 'Hybrid',
                              max_participants: 40,
                              max_virtual: 300)

            visit edit_event_path(@event)
            fill_in 'event_event_format', with: 'Physical'
          end

          it 'does not change max_participants if no change submitted' do
            click_button "Update Event"
            event = Event.find(@event.code)
            expect(event.max_participants).to eq(40)
          end

          it "sets max_participants to default value if 0 submitted" do
            sets_max_participants_to_default
          end

          it 'sets max_participants non-zero value submitted' do
            sets_to_user_entered('max_participants', 55)
          end

          it 'sets max_virtual to 0' do
            click_button "Update Event"
            event = Event.find(@event.code)
            expect(event.max_virtual).to eq(0)
          end
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
      @allowed_fields = %w(short_name description press_release door_code
        booking_code name code max_participants max_observers start_date
        end_date time_zone location subjects event_format)
      @not_allowed_fields = %w(id updated_by created_at updated_at
        confirmed_count publish_schedule)
      visit edit_event_path(@event)
    end

    it 'allows access' do
      expect(current_path).to eq(edit_event_path(@event))
    end

    it 'has Delete button' do
      has_delete_button
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

    it 'updates fields when submitted' do
      fill_in 'event[start_date]', with: '2030-02-02'
      fill_in 'event[end_date]', with: '2030-02-07'
      select 'Auckland', from: 'event[time_zone]'
      select Setting.Locations.keys.last, from: 'event[location]'

      click_button "Update Event"

      event = Event.find(@event.code)
      expect(event.start_date).to eq(DateTime.parse('2030-02-02'))
      expect(event.end_date).to eq(DateTime.parse('2030-02-07'))
      expect(event.time_zone).to eq('Auckland')
      expect(event.location).to eq(Setting.Locations.keys.last)
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
      has_delete_button
    end
  end
end
