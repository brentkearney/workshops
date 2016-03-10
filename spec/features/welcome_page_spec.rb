# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Post-login Welcome Page', :type => :feature do

  before do
    Person.destroy_all
    Event.destroy_all
    @user = create(:user, password: 'secret123456', password_confirmation: 'secret123456')
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
      Event.destroy_all
      @user.member!
      5.times { create(:membership, person: @user.person, role: 'Participant') }
    end

    after(:each) do
      @user.logout
    end

    it 'redirects to the welcome path' do
      sign_in_as @user

      expect(current_path).to eq(welcome_path)
    end

    it "shows the user's current and upcoming workshops" do
      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      @user.person.memberships.each do |m|
        expect(page.body).to include("#{m.event.code}")
        expect(page.body).to include("#{m.event.name}")
      end
    end

    it "excludes the user's past workshops" do
      event = @user.person.events.sample
      event.start_date = Date.today.prev_year.prev_week(:sunday)
      event.end_date = Date.today.prev_year.prev_week(:sunday) + 5.days
      event.save!

      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      expect(page.body).not_to include("#{event.name}")

      event.destroy!
    end

    it 'does not show the workshops for which the user is Not Yet Invited' do
      membership = @user.person.memberships.sample
      membership.attendance = 'Not Yet Invited'
      membership.save!

      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      expect(page.body).not_to include("#{membership.event.name}")

      membership.destroy!
    end

    it 'does not show the workshops for which the user has Declined' do
      membership = @user.person.memberships.sample
      membership.attendance = 'Declined'
      membership.save!

      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      expect(page.body).not_to include("#{membership.event.name}")

      membership.destroy!
    end

    it 'does not show the workshops for which the user is a Backup Participant' do
      membership = @user.person.memberships.sample
      membership.role = 'Backup Participant'
      membership.save!

      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      expect(page.body).not_to include("#{membership.event.name}")

      membership.destroy!
    end
  end

  context 'As an event organizer' do
    before do
      Event.destroy_all
      @user.member!
      3.times { create(:membership, person: @user.person, role: 'Organizer') }
    end

    after(:each) do
      @user.logout
    end

    it "shows the user's current and upcoming workshops" do
      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      @user.person.memberships.each do |m|
        expect(page.body).to include("#{m.event.code}")
        expect(page.body).to include("#{m.event.name}")
      end
    end

    it 'shows the workshops for which the user is Not Yet Invited' do
      membership = @user.person.memberships.sample
      membership.attendance = 'Not Yet Invited'
      membership.save!

      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      expect(page.body).to include("#{membership.event.name}")

      membership.destroy!
    end

    it 'shows the workshops for which the user has Declined' do
      membership = @user.person.memberships.sample
      membership.attendance = 'Declined'
      membership.save!

      sign_in_as @user

      expect(current_path).to eq(welcome_path)
      expect(page.body).to include("#{membership.event.name}")

      membership.destroy!
    end

  end

end
