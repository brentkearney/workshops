# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Email address sharing', type: :feature do
  before do
    @event = create(:event_with_members)
    @member = create(:membership, event: @event, attendance: 'Confirmed')
    @user = create(:user, person: @member.person)
    @non_member_user = create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def shows_member_emails
    @event.memberships.where(attendance: 'Confirmed').each do |membership|
      expect(page.body).to include(membership.person.email)
    end
  end

  def shows_invited_emails
    @event.memberships.where(attendance: 'Invited')
          .or(@event.memberships.where(attendance: 'Undecided'))
          .each do |membership|
      expect(page.body).to include(membership.person.email)
    end
  end

  def does_not_show_member_emails
    @event.memberships.where(attendance: 'Confirmed').each do |membership|
      expect(page.body).not_to include(membership.person.email)
    end
  end

  def does_not_show_invited_emails
    @event.memberships.where(attendance: 'Invited')
          .or(@event.memberships.where(attendance: 'Undecided'))
          .each do |membership|
      expect(page.body).not_to include(membership.person.email)
    end
  end

  def unshare_some_emails
    @unshared1 = @event.memberships.where(attendance: 'Confirmed', role: 'Participant').first
    expect(@unshared1.person).not_to eq(@user.person)
    @unshared1.share_email = false
    @unshared1.save

    @unshared2 = @event.memberships.where(attendance: 'Confirmed', role: 'Participant').second
    expect(@unshared2.person).not_to eq(@user.person)
    @unshared2.share_email = false
    @unshared2.save
  end

  def reshare_those_emails
    @unshared1.share_email = true
    @unshared1.save
    @unshared2.share_email = true
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

  context 'As a not-logged in user' do
    before do
      logout(@user)
      visit event_memberships_path(@event)
    end

    it 'does not show member email addresses' do
      does_not_show_member_emails
      does_not_show_invited_emails
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'does not show member email addresses' do
      does_not_show_member_emails
      does_not_show_invited_emails
    end
  end

  context 'As a logged-in user who is a member of the event' do
    before do
      @user.member!
      @member.role = 'Participant'
      @member.save
      login_as @user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows member email addresses' do
      shows_member_emails
    end

    it 'hides emails of those who choose not to share' do
      unshare_some_emails
      visit event_memberships_path(@event)

      expect(page.body).not_to include(@unshared1.person.email)
      expect(page.body).not_to include(@unshared2.person.email)
      reshare_those_emails
    end

    it 'hides emails of unconfirmed members' do
      does_not_show_invited_emails
    end
  end

  context 'As an organizer of the event' do
    before do
      membership = @user.person.memberships.where(event: @event).first
      membership.role = 'Organizer'
      membership.save
      login_as @user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'shows confirmed, invited, and undecided email addresses' do
      shows_member_emails
      shows_invited_emails
    end

    it 'hides emails of those who choose not to share, but still adds mailto: links' do
      unshare_some_emails
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      hides_emails_but_links_to_them
      reshare_those_emails
    end
  end

  context 'As an organizer of a different event' do
    before do
      @new_event = create(:event)
      m = create(:membership, event: @new_event, role: 'Organizer')
      new_user = create(:user, email: m.person.email, person: m.person)
      login_as new_user, scope: :user
      visit event_memberships_path(@event)
    end

    it 'does not show member or invited email addresses' do
      does_not_show_member_emails
      does_not_show_invited_emails
    end
  end

  context 'As a staff user' do
    before do
      @non_member_user.staff!
      login_as @non_member_user, scope: :user
    end

    it 'shows member & invited email addresses if staff location matches event location' do
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      shows_member_emails
      shows_invited_emails
    end

    it 'hides emails of those who choose not to share, but still adds mailto: links' do
      unshare_some_emails
      @non_member_user.location = @event.location
      @non_member_user.save!

      visit event_memberships_path(@event)
      hides_emails_but_links_to_them
      reshare_those_emails
    end

    it 'does not show member or invited email addresses if staff location does not match event location' do
      @non_member_user.location = 'Elsewhere'
      @non_member_user.save!

      visit event_memberships_path(@event)
      does_not_show_member_emails
      does_not_show_invited_emails
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.admin!
      login_as @non_member_user, scope: :user
    end

    it 'shows member and invited email addresses' do
      visit event_memberships_path(@event)
      shows_member_emails
      shows_invited_emails
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
