# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Events Admin Dashboard', type: :feature do
  before do
  	@event = create(:event)
  	person = create(:person)
  	create(:membership, event: @event, person: person, role: 'Organizer')

  	@member_user = create(:user,email: person.email,person: person, role: 0)
    @staff_user = create(:user, :staff)
    @admin_user = create(:user, :admin)
    @super_admin_user = create(:user, :super_admin)
  end

  after(:each) do
    Warden.test_reset!
  end

  def fill_in_new_events_fields
  	fill_in 'Code', with: '23w0001'
	  fill_in 'Name', with: '5 Day Workshop Schedule Template'
	  fill_in "Short name", with: 'Schedule template'
	  fill_in 'Start date', with: Time.now + 1.days
	  fill_in 'End date', with: Time.now + 3.days
	  fill_in 'Event type', with: 'Summer School'
	  fill_in 'Location', with: 'EO'
	  fill_in 'Description', with: 'Description for testing purposes'
	  fill_in 'Max participants', with: 5
	  fill_in 'Door code', with: 12
	  fill_in 'Updated by', with: 'Capybara'
    select 'Mountain Time (US & Canada)', from: 'event[time_zone]'
	  check 'Template'

	  click_on('Create Event')
  end

  context 'As a not-logged in user' do
    before do
      visit 'admin/events'
    end

    it "should redirect to root path" do
      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content("You need to sign in or sign up before continuing")
    end
  end

  context 'As a member user' do
    before do
      login_as @member_user, scope: :user
      visit 'admin/events'
    end

    it "should redirect to root path" do
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Access denied")
    end
  end

  context 'As a staff user' do
    before do
      login_as @staff_user, scope: :user
      visit 'admin/lectures'
    end

    it "should redirect to root path" do
      expect(page).to have_current_path(admin_people_path)
      expect(page).to have_content("Access denied")
    end

  end

  context 'As a admin user' do
    before do
      login_as @admin_user, scope: :user
      visit 'admin/events'
    end
    it "should display admin events dashboard" do
      expect(page).to have_current_path(admin_events_path)
	  end

	  it "can create new event" do
	    click_link('New event')

	    fill_in_new_events_fields

	    visit admin_events_path

	    expect(page).to have_content('23w0001')
	  end
  end

  context 'As a super_admin user' do
    before do
      login_as @super_admin_user, scope: :user
      visit 'admin/events'
    end

    it "should display admin events dashboard" do
      expect(page).to have_current_path(admin_events_path)
    end

    it "can create new event" do
      click_link('New event')

      fill_in_new_events_fields

      visit admin_events_path

      expect(page).to have_content('23w0001')
    end
  end
end
