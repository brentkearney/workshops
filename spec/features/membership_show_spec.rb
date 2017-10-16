# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Membership Show Page', type: :feature do
  before do
    Event.destroy_all
    @event = create(:event_with_members)
    @organizer = @event.memberships.where("role='Contact Organizer'").first
    @participant = @event.memberships.where("role='Participant'").first
    @participant_user = create(:user, email: @participant.person.email,
                                      person: @participant.person)
    @non_member_user = create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def shows_basic_info(member)
    expect(page.body).to have_css('div#profile-name', text: member.person.name)
    expect(page.body).to have_css('div#profile-role', text: member.role)
    expect(page.body).to have_css('div#profile-affil',
                                  text: member.person.affil_with_title)
    expect(page.body).to have_css('div#profile-url', text: member.person.uri)
  end

  def shows_limited_profile(member)
    shows_basic_info(member)
    expect(page.body).not_to have_text('Arriving on')
    expect(page.body).not_to have_text('Departing on')
    expect(page.body).not_to have_text('RSVP date')
    expect(page.body).not_to have_text(member.rsvp_date)
  end

  def shows_limited_profile_without_email(member)
    shows_limited_profile(member)
    expect(page.body).not_to have_text(member.person.email)
  end

  def shows_limited_profile_with_email(member)
    shows_limited_profile(member)
    expect(page.body).to have_text(member.person.email)
  end

  def shows_limited_profile_with_email_and_dates(member)
    shows_basic_info(member)
    expect(page.body).to have_text(member.person.email)

    arrival_date = member.arrival_date.strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-arrival', text: arrival_date)

    departure_date = member.departure_date.strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-departure', text: departure_date)
    expect(page.body).to have_css('div#profile-replied-at',
                                  text: member.rsvp_date)
  end

  def shows_full_profile(member)
    shows_limited_profile_with_email_and_dates(member)
    expect(page.body).to have_css('div#profile-address')
    expect(page.body).to have_css('div#profile-billing')
    expect(page.body).to have_css('div#profile-special-info')
    expect(page.body).to have_css('div#profile-has-guest')
    expect(page.body).to have_css('div#profile-staff-notes')
    expect(page.body).to have_css('div#profile-org-notes')
    expect(page.body).to have_css('div#profile-reviewed')
    expect(page.body).to have_css('div#profile-updated-by',
                                  text: member.updated_by)
    expect(page.body).to have_text(member.updated_at)
  end


  context 'As a not-logged in user' do
    before do
      visit event_membership_path(@event, @organizer)
    end

    it 'shows a limited profile without email' do
      shows_limited_profile_without_email(@organizer)
    end
  end


  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit event_membership_path(@event, @organizer)
    end

    it 'shows a limited profile without email' do
      shows_limited_profile_without_email(@organizer)
    end
  end


  context 'As a logged-in user who is a member of the event' do
    before do
      login_as @participant_user, scope: :user
      visit event_membership_path(@event, @organizer)
    end

    it 'shows a limited profile with email' do
      shows_limited_profile_with_email(@organizer)
    end
  end


  context 'As a logged-in user who is an organizer of the event' do
    before do
      person = @organizer.person
      user = create(:user, email: person.email, person: person)
      login_as user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows a limited profile with email and dates' do
      shows_limited_profile_with_email_and_dates(@participant)
    end
  end

  context 'As a staff user' do
    before do
      @non_member_user.staff!
      login_as @non_member_user, scope: :user
    end

    context 'whose location does NOT match the event location' do
      before do
        @non_member_user.location = 'Somewhere else'
        @non_member_user.save!
        visit event_membership_path(@event, @participant)
      end

      it 'shows a limited profile without email' do
        shows_limited_profile_without_email(@participant)
      end
    end

    context 'whose location matches the event location' do
      before do
        @non_member_user.location = @event.location
        @non_member_user.save!
        visit event_membership_path(@event, @participant)
      end

      it 'shows full profile information' do
        shows_full_profile(@participant)
      end
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.admin!
      login_as @non_member_user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows full profile information' do
      shows_full_profile(@participant)
    end
  end
end
