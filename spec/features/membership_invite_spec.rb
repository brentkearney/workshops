# ./spec/features/membership_add_spec.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Membership invitations', type: :feature do
  before do
    @event = create(:event_with_members)
    @event.start_date = (Date.current + 1.month).beginning_of_week(:sunday)
    @event.end_date = @event.start_date + 5.days
    @event.save
    organizer = @event.memberships.where("role='Contact Organizer'").first
    @org_user = create(:user, email: organizer.person.email,
                             person: organizer.person)
    @participant = @event.memberships.where("role='Participant'").first
    @user = create(:user)
  end

  describe 'Visibility of Invite Members link, access to page' do
    it 'hides from and denies access to public users' do
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Invite Members")

      visit invite_event_memberships_path(@event)
      expect(current_path).to eq(user_session_path)
      expect(page).to have_text('You need to sign in')
    end

    it 'shows to and allows access to organizer users' do
      login_as @org_user, scope: :user
      visit event_memberships_path(@event)
      expect(page).to have_link("Invite Members")

      click_link("Invite Members")
      expect(current_path).to eq(invite_event_memberships_path(@event))
      logout(@org_user)
    end
  end

  describe 'Send Invitation buttons' do
    it 'are hidden from public users' do
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Send Invitation")

      visit invitations_send_path(@participant)
      expect(current_path).to eq(user_session_path)
      expect(page).to have_text('You need to sign in')
    end

    it 'are hidden from non-member users' do
      login_as @user, scope: :user
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Send Invitation")

      visit invitations_send_path(@participant)
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text('Access to this feature is restricted')

      logout(@user)
    end

    it 'are hidden from member users' do
      @user.email = @participant.person.email
      @user.person = @participant.person
      @user.save

      login_as @user, scope: :user
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Send Invitation")

      visit invitations_send_path(@participant)
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text('Access to this feature is restricted')

      logout(@user)
    end

    it 'are available to organizer users' do
      login_as @org_user, scope: :user
      visit event_memberships_path(@event)
      expect(page).to have_link("Send Invitation")
      participant = @event.memberships.where(role: 'Participant')
                                      .where(attendance: 'Not Yet Invited').last
      expect(participant).not_to be_blank

      visit invitations_send_path(participant)

      expect(current_path).to eq(event_memberships_path(@event))
      expect(Membership.find(participant.id).attendance).to eq('Invited')
      logout(@org_user)
    end

    it 'are available to staff users' do
      @user.staff!
      login_as @user
      visit event_memberships_path(@event)
      expect(page).to have_link("Send Invitation")

      participant = @event.memberships.where(role: 'Participant')
                                      .where(attendance: 'Not Yet Invited').last
      expect(participant).not_to be_blank

      visit invitations_send_path(participant)

      expect(current_path).to eq(event_memberships_path(@event))
      expect(Membership.find(participant.id).attendance).to eq('Invited')
      logout(@user)
    end

    it 'are available to admin users' do
      @user.admin!
      login_as @user
      visit event_memberships_path(@event)
      expect(page).to have_link("Send Invitation")
      participant = @event.memberships.where(role: 'Participant')
                                      .where(attendance: 'Not Yet Invited').last
      expect(participant).not_to be_blank

      visit invitations_send_path(participant)

      expect(current_path).to eq(event_memberships_path(@event))
      expect(Membership.find(participant.id).attendance).to eq('Invited')
      logout(@user)
    end

    it 'are hidden if the event is in the past' do
      @event.start_date = (Date.current - 1.month).beginning_of_week(:sunday)
      @event.end_date = @event.start_date + 5.days
      @event.save

      login_as @org_user, scope: :user
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Send Invitation")

      visit invitations_send_path(@participant)
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text('Access to this feature is restricted')

      @event.start_date = (Date.current + 1.month).beginning_of_week(:sunday)
      @event.end_date = @event.start_date + 5.days
      @event.save
      logout(@org_user)
    end
  end

  describe 'Sending Invitations' do
    it 'fails if max_participants is exceeded' do
      num_participants = @event.num_invited_participants
      @event.max_participants = num_participants
      @event.save!

      @user.admin!
      login_as @user
      visit event_memberships_path(@event)

      participant = @event.memberships.where(role: 'Participant')
                                      .where(attendance: 'Not Yet Invited').last
      expect(participant).not_to be_blank

      visit invitations_send_path(participant)

      expect(Membership.find(participant.id).attendance).to eq('Not Yet Invited')
      expect(page).to have_text("This event is already full")
    end

    it 'fails if max_observers is exceeded' do
      num_observers = @event.num_invited_observers
      @event.max_observers = num_observers
      @event.save!

      @user.admin!
      login_as @user
      visit event_memberships_path(@event)
      observer = @event.memberships.where(role: 'Observer')
                                      .where(attendance: 'Not Yet Invited').last
      expect(observer).not_to be_blank

      visit invitations_send_path(observer)

      expect(Membership.find(observer.id).attendance).to eq('Not Yet Invited')
      expect(page).to have_text("You may not invite more than
        #{@event.max_observers} observers".squish)
    end

    it 'does not fail if max_participants is full, but observer is invited' do
      num_participants = @event.num_invited_participants
      @event.max_participants = num_participants
      num_observers = @event.num_invited_observers
      @event.max_observers = num_observers + 1
      @event.save!

      @user.admin!
      login_as @user
      visit event_memberships_path(@event)

      observer = create(:membership, event: @event, role: 'Observer',
                                attendance: 'Not Yet Invited')
      visit invitations_send_path(observer)

      expect(Membership.find(observer.id).attendance).to eq('Invited')
      expect(page).to have_text("Invitation sent to #{observer.person.name}")
    end
  end
end
