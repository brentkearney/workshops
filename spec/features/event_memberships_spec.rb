# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Membership Page', :type => :feature do
  before do
    @event = create(:event_with_members)
    @member = @event.memberships.where("role='Participant'").first
    @user = create(:user, email: @member.person.email, person: @member.person)
    @non_member_user = create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def does_not_list_members
    @event.members.each do |p|
      expect(page.body).not_to include(p.lastname)
    end
  end

  def shows_confirmed_members
    @event.memberships.select {|m| m.attendance == 'Confirmed'}.each do |member|
      expect(page.body).to include(member.person.lname)
    end
  end

  def hides_nonconfirmed_members
    @event.memberships.select {|m| m.attendance != 'Confirmed'}.each do |member|
      expect(page.body).not_to include(member.person.lname)
    end
  end

  def shows_all_members
    @event.memberships.each do |member|
      expect(page.body).to include(member.person.lname)
    end
  end

  def shows_email_buttons
    expect(page.body).to have_css('a', text: 'Email Organizers')
    expect(page.body).to have_css('a', text: 'Email Confirmed Members')
  end

  def hides_email_buttons
    expect(page.body).not_to have_css('a', text: 'Email Organizers')
    expect(page.body).not_to have_css('a', text: 'Email Confirmed Members')
  end

  def shows_limited_profile(member)
    expect(page.body).to have_css('div.profile-name', text: "#{member.person.name}")
    expect(page.body).to have_css('div.profile-affil', text: "#{member.person.affil_with_title}")
    expect(page.body).to have_css('div.profile-url', text: "#{member.person.url}")

    expect(page.body).not_to include('Arriving on')
    expect(page.body).not_to include(member.arrival_date.to_s)
    expect(page.body).not_to include('Departing on')
    expect(page.body).not_to include(member.departure_date.to_s)
    expect(page.body).not_to include('Replied at')
    expect(page.body).not_to include(member.replied_at.to_s)
  end

  def shows_full_profile(member)
    expect(page.body).to have_css('div.profile-name', text: "#{member.person.name}")
    expect(page.body).to have_css('div.profile-affil', text: "#{member.person.affil_with_title}")
    expect(page.body).to have_css('div.profile-email', text: "#{member.person.email}")
    expect(page.body).to have_css('div.profile-url', text: "#{member.person.url}")

    expect(page.body).to include('Arriving on')
    expect(page.body).to include(member.arrival_date.to_s)
    expect(page.body).to include('Departing on')
    expect(page.body).to include(member.departure_date.to_s)
    expect(page.body).to include('Replied at')
    expect(page.body).to include(member.replied_at.to_s)
  end

  context 'As a not-logged in user' do
    before do
      visit event_memberships_path(@event)
    end

    it 'does not show member email addresses' do
      does_not_list_members
    end

    it 'hides email buttons' do
      hides_email_buttons
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows confirmed members' do
      shows_confirmed_members
    end

    it 'hides email buttons' do
      hides_email_buttons
    end

    it 'does not show non-confirmed members' do
      hides_nonconfirmed_members
    end

    it 'clicking a member shows limited profile information, excludes email address' do
      member = @event.memberships.where("role='Participant' AND attendance='Confirmed'").last
      click_link "#{member.person.lname}"
      shows_limited_profile(member)
      expect(page.body).not_to include(member.person.email)
    end
  end

  context 'As a logged-in user who is a member of the event' do
    before do
      login_as @user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows confirmed members' do
      shows_confirmed_members
    end

    it 'hides email buttons' do
      hides_email_buttons
    end

    it 'does not show non-confirmed members' do
      hides_nonconfirmed_members
    end

    it 'clicking a member shows limited profile information, but includes the email address' do
      member = @event.memberships.where("role='Participant' AND attendance='Confirmed'").last
      click_link "#{member.person.lname}"
      shows_limited_profile(member)
      expect(page.body).to include(member.person.email)
    end
  end

  context 'As an organizer of the event' do
    before do
      organizer = @event.memberships.where("role='Organizer'").first.person
      user = create(:user, email: organizer.email, person: organizer)
      login_as user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows all members of the event' do
      shows_all_members
    end

    it 'shows email buttons' do
      shows_email_buttons
    end

    it 'creates sections for attendance status' do
      @event.memberships.map { |member| member.attendance }.uniq.each do |status|
        expect(page.body).to have_css('div', text: "#{status}")
      end
    end

    it 'clicking a member shows full profile information' do
      member = @event.memberships.where("role='Participant' AND attendance='Confirmed'").last
      click_link "#{member.person.lname}"
      shows_full_profile(member)
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
        visit event_memberships_path(@event)
      end

      it 'shows all members' do
        shows_all_members
      end

      it 'shows email buttons' do
        shows_email_buttons
      end

      it 'clicking a member shows full profile information' do
        member = @event.memberships.where("role='Participant' AND attendance='Confirmed'").last
        click_link "#{member.person.lname}"
        shows_full_profile(member)
      end
    end

    context 'whose location does NOT match the event location' do
      before do
        @non_member_user.location = 'Somewhere else'
        @non_member_user.save!
        visit event_memberships_path(@event)
      end

      it 'shows only confirmed members' do
        hides_nonconfirmed_members
      end

      it 'hides email buttons' do
        hides_email_buttons
      end

      it 'clicking a member shows limited profile information, excludes the email address' do
        member = @event.memberships.where("role='Participant' AND attendance='Confirmed'").last
        click_link "#{member.person.lname}"
        shows_limited_profile(member)
        expect(page.body).not_to include(member.person.email)
      end
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.admin!
      login_as @non_member_user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows all members of the event' do
      shows_all_members
    end

    it 'shows email buttons' do
      shows_email_buttons
    end

    it 'clicking a member shows full profile information' do
      member = @event.memberships.where("role='Participant' AND attendance='Confirmed'").last
      click_link "#{member.person.lname}"
      shows_full_profile(member)
    end
  end
end
