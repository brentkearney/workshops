# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Membership Page', type: :feature do
  before do
    @event = create(:event_with_members)
    @member = @event.memberships.where("role='Participant'").first
    @user = create(:user, email: @member.person.email, person: @member.person)
    @non_member_user = create(:user)
  end

  def links_to_profile(member)
    expect(page).to have_link(nil, href: event_membership_path(@event, member))
  end

  def does_not_list_members
    @event.members.each do |p|
      expect(page.body).not_to have_text(p.lastname)
    end
  end

  def shows_confirmed_members
    @event.memberships.select {|m| m.attendance == 'Confirmed'}.each do |member|
      expect(page.body).to have_text(member.person.lname)
    end
  end

  def hides_nonconfirmed_members
    @event.memberships.select {|m| m.attendance != 'Confirmed' &&
      m.attendance != 'Undecided' &&
      m.attendance != 'Invited' }.each do |member|
      expect(page.body).not_to have_text(member.person.lname)
    end
  end

  def shows_all_members
    @event.memberships.each do |member|
      expect(page.body).to have_text(member.person.lname)
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

  def shows_invite_buttons
    expect(page.body).to have_css('a', text: 'Send Invitation')
  end

  def hides_invite_buttons
    expect(page.body).not_to have_css('a', text: 'Send Invitation')
  end

  def shows_reinvite_buttons
    expect(page.body).to have_css('a', text: 'Resend Invitation')
  end

  def hides_reinvite_buttons
    expect(page.body).not_to have_css('a', text: 'Resend Invitation')
  end

  def links_to_confirmed_member_profiles
    @event.memberships.select {|m| m.attendance == 'Confirmed'}.each do |member|
      links_to_profile(member)
    end
  end

  def links_to_all_member_profiles
    @event.memberships.each do |member|
      links_to_profile(member)
    end
  end

  context 'As a not-logged in user' do
    before do
      visit event_memberships_path(@event)
    end

    it 'does not show a list of confirmed participants' do
      does_not_list_members
    end

    it 'does not show member email addresses' do
      @event.memberships.each do |member|
        expect(page.body).not_to have_text(member.person.email)
      end
    end

    it 'hides email & invite buttons' do
      hides_email_buttons
      hides_invite_buttons
      hides_reinvite_buttons
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

    it 'hides email & invite buttons' do
      hides_email_buttons
      hides_invite_buttons
      hides_reinvite_buttons
    end

    it 'does not show non-confirmed members' do
      hides_nonconfirmed_members
    end

    it "has links to Confirmed participants' profiles" do
      links_to_confirmed_member_profiles
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

    it 'shows email buttons' do
      shows_email_buttons
    end

    it 'hides invite buttons' do
      hides_invite_buttons
      hides_reinvite_buttons
    end

    it 'does not show non-confirmed members' do
      hides_nonconfirmed_members
    end

    it "has links to Confirmed participants' profiles" do
      links_to_confirmed_member_profiles
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

    it 'shows email & invite buttons' do
      shows_email_buttons
      shows_invite_buttons
      shows_reinvite_buttons
    end

    it 'creates sections for attendance status' do
      @event.memberships.map { |member| member.attendance }.uniq.each do |status|
        expect(page.body).to have_css('div', text: "#{status}")
      end
    end

    it "has links to all members' profiles" do
      links_to_all_member_profiles
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

      it 'shows email & invite buttons' do
        shows_email_buttons
        shows_invite_buttons
        shows_reinvite_buttons
      end

      it "has links to all members' profiles" do
        links_to_all_member_profiles
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
        hides_invite_buttons
        hides_reinvite_buttons
      end

      it "has links to Confirmed participants' profiles" do
        links_to_confirmed_member_profiles
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

    it 'shows email & invite buttons' do
      shows_email_buttons
      shows_invite_buttons
      shows_reinvite_buttons
    end

    it "has links to all members' profiles" do
      links_to_all_member_profiles
    end
  end
end
