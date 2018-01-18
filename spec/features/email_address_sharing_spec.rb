# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Email address sharing', :type => :feature do
  before do
    @event = FactoryBot.create(:event)
    5.times do
      person = FactoryBot.create(:person)
      membership = FactoryBot.create(:membership, event: @event, person: person, role: 'Participant')
      user = FactoryBot.create(:user, email: person.email, person: person)
    end

    @member = @event.members.first
    @user = User.find_by_email(@member.email)
    expect(@user).not_to be_nil

    @non_member_user = FactoryBot.create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def shows_member_emails
    @event.members.each do |member|
      expect(page.body).to include(member.email)
    end
  end

  def does_not_show_member_emails
    @event.members.each do |member|
      expect(page.body).not_to include(member.email)
    end
  end

  def unshare_some_emails
    @unshared1 = @event.memberships.first
    @unshared1.share_email = false
    @unshared1.save

    @unshared2 = @event.memberships.last
    @unshared2.share_email = false
    @unshared2.save
  end

  def hides_emails_but_links_to_them
    @event.memberships.each do |membership|
      email = membership.person.email
      if email == @unshared1.person.email || email == @unshared2.person.email
        expect(page.body).to match(/<a title="E-mail not shared with other members" href="mailto:#{email}.+">\[not shared\]<\/a>/)
      else
        expect(page.body).to match(/<a href="mailto:#{email}.+">#{email}<\/a>/)
      end
    end
  end

  def does_not_show_email_button
    expect(page.body).not_to have_css('a.email-members')
    expect(page.body).not_to include('Email Confirmed Members')
  end

  def shows_email_button
    expect(page.body).to have_css('a.email-members')
    expect(page.body).to include('Email Confirmed Members')
  end

  context 'As a not-logged in user' do
    before do
      visit event_memberships_path(@event)
    end

    it 'does not show member email addresses' do
      does_not_show_member_emails
    end

    it 'does not show "Email Confirmed Members" button' do
      does_not_show_email_button
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'does not show member email addresses' do
      does_not_show_member_emails
    end

    it 'does not show "Email Confirmed Members" button' do
      does_not_show_email_button
    end
  end

  context 'As a logged-in user who is a member of the event' do
    before do
      login_as @user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows member email addresses' do
      shows_member_emails
    end

    it 'hides emails of those who choose not to share' do
      unshare_some_emails
      visit event_memberships_path(@event)

      @event.memberships.each do |membership|
        if membership == @unshared1 || membership == @unshared2
          expect(page.body).not_to include(membership.person.email)
        else
          expect(page.body).to include(membership.person.email)
        end
      end
    end

    it 'does not show "Email Confirmed Members" button' do
      does_not_show_email_button
    end
  end

  context 'As an organizer of the event' do
    before do
      membership = @event.memberships.first
      membership.role = 'Organizer'
      membership.save!
      login_as @user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows member email addresses' do
      shows_member_emails
    end

    it 'hides emails of those who choose not to share, but still adds mailto: links' do
      unshare_some_emails
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      hides_emails_but_links_to_them
    end

    it 'shows "Email Confirmed Members" button' do
      shows_email_button
    end
  end

  context 'As an organizer of a different event' do
    before do
      @new_event = FactoryBot.create(:event)
      new_person = FactoryBot.create(:person)
      new_membership = FactoryBot.create(:membership, event: @new_event, person: new_person, role: 'Organizer')
      new_user = FactoryBot.create(:user, email: new_person.email, person: new_person)
      login_as new_user, scope: :user
    end

    it 'does not show member email addresses' do
      visit event_memberships_path(@event)
      does_not_show_member_emails
    end

    it 'does not show "Email Confirmed Members" button' do
      does_not_show_email_button
    end
  end

  context 'As a staff user' do
    before do
      @non_member_user.staff!
      login_as @non_member_user, scope: :user
    end
    
    it 'shows member email addresses if staff location matches event location' do
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      shows_member_emails
    end

    it 'shows "Email Confirmed Members" button if staff location matches event location' do
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      shows_email_button
    end

    it 'hides emails of those who choose not to share, but still adds mailto: links' do
      unshare_some_emails
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      hides_emails_but_links_to_them
    end

    it 'does not show member email addresses if staff location does not match event location' do
      @non_member_user.location = 'Elsewhere'
      @non_member_user.save!

      visit event_memberships_path(@event)
      does_not_show_member_emails
    end

    it 'does not show "Email Confirmed Members" button if staff location does not match event location' do
      @non_member_user.location = 'Elsewhere'
      @non_member_user.save!

      does_not_show_email_button
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.admin!
      login_as @non_member_user, scope: :user
    end

    it 'shows member email addresses' do
      visit event_memberships_path(@event)
      shows_member_emails
    end

    it 'shows "Email Confirmed Members" button' do
      visit event_memberships_path(@event)
      shows_email_button
    end

    it 'hides emails of those who choose not to share, but still adds mailto: links' do
      unshare_some_emails
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      hides_emails_but_links_to_them
    end
  end
end
