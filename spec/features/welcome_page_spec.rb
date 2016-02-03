# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Post-login Welcome Page', :type => :feature do

  before do
    Person.destroy_all
    Event.destroy_all
    @user = FactoryGirl.create(:user, password: 'secret123456', password_confirmation: 'secret123456')
  end

  after(:each) do
    Warden.test_reset!
  end

  def sign_in_as(user)
    visit sign_in_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'secret123456'
    click_button 'Sign in'
  end

  it 'Disallows access to non-logged in users' do
    visit welcome_path

    expect(current_path).to eq(new_user_session_path)
  end

  context 'As an event participant' do
    before do
      expect(@user).not_to be_nil
      @user.member!
      3.times do
        FactoryGirl.create(:membership, person: @user.person, role: 'Participant')
      end
    end

    after(:each) do
      @user.logout
    end

    it 'redirects to the participant welcome path' do
      sign_in_as @user
      expect(current_path).to eq(welcome_member_path)
    end

    it 'shows the user\'s current and upcoming workshops' do
      sign_in_as @user

      @user.person.memberships.each do |m|
        expect(page.body).to include("#{m.event.code}")
        expect(page.body).to include("#{m.event.name}")
      end
    end
  end

  context 'As an event organizer' do
    before do
      expect(@user).not_to be_nil
      @user.member!
      3.times do
        FactoryGirl.create(:membership, person: @user.person, role: 'Organizer')
      end
    end

    it 'redirects to the organizer welcome path' do
      sign_in_as @user
      expect(current_path).to eq(welcome_organizers_path)
    end

    it 'shows the user\'s current and upcoming workshops' do
      sign_in_as @user

      @user.person.memberships.each do |m|
        expect(page.body).to include("#{m.event.code}")
        expect(page.body).to include("#{m.event.name}")
      end
    end

    it 'shows links to current workshop schedules' do
      sign_in_as @user
      @user.person.memberships.each do |m|
        expect(page.body).to have_link("Manage Schedule", :href => event_schedule_index_path(m.event))
      end
    end

    it 'shows links to current workshop members' do
      sign_in_as @user
      @user.person.memberships.each do |m|
        expect(page.body).to have_link("View Members", :href => event_memberships_path(m.event))
      end
    end
  end

  context 'As a staff user' do
    before do
      expect(@user).not_to be_nil
      @user.staff!
      @template_event = FactoryGirl.create(:event, template: true)
    end

    it 'redirects to staff welcome path' do
      sign_in_as @user
      expect(current_path).to eq(welcome_staff_path)
    end

    it 'redirects to staff welcome path, even when staff is an organizer of a template event' do
      FactoryGirl.create(:membership, event: @template_event, person: @user.person, role: 'Organizer')
      sign_in_as @user
      expect(current_path).to eq(welcome_staff_path)
    end

    it 'shows the current and upcoming events, with links to their schedules' do
      sign_in_as @user
      Event.where("start_date >= ?", 2.weeks.ago).each do |event|
        expect(page.body).to include(event.code)
        expect(page.body).to include(event.name)
        expect(page.body).to have_link("Manage Schedule", :href => event_schedule_index_path(event))
      end
    end

    it 'excludes events that are not at the staff member\'s location' do
      future_event = Event.where("start_date >= ?", 1.week.from_now).first
      future_event.location = 'Elsewhere'
      future_event.save!
      sign_in_as @user
      expect(page.body).not_to include(future_event.code)
      expect(page.body).not_to include(future_event.name)
    end

    it 'shows the template events for the user\'s location, with links to their schedules' do
      e1 = Event.first
      e1.template = true
      e1.location = @user.location
      e1.save!
      e2 = Event.first
      e2.template = true
      e2.location = @user.location
      e2.save!

      sign_in_as @user
      Event.select {|e| e.template == true && e.location == @user.location }.each do |event|
        expect(page.body).to include(event.code)
        expect(page.body).to include(event.name)
        expect(page.body).to have_link("Manage Schedule", :href => event_schedule_index_path(event))
      end
    end
  end

  context 'As an admin user' do
    before do
      expect(@user).not_to be_nil
      @user.admin!
      @template_event = FactoryGirl.create(:event, template: true)
    end

    it 'redirects to admin welcome path' do
      sign_in_as @user
      expect(current_path).to eq(welcome_admin_path)
    end

    it 'redirects to staff welcome path, even when staff is an organizer of a template event' do
      FactoryGirl.create(:membership, event: @template_event, person: @user.person, role: 'Organizer')
      sign_in_as @user
      expect(current_path).to eq(welcome_admin_path)
    end

    it 'shows the current and upcoming events, with links to their schedules' do
      sign_in_as @user
      Event.where("start_date >= ?", 2.weeks.ago).each do |event|
        expect(page.body).to include(event.code)
        expect(page.body).to include(event.name)
        expect(page.body).to have_link("Manage Schedule", :href => event_schedule_index_path(event))
      end
    end
  end
end
