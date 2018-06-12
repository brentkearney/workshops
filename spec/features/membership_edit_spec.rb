# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Membership#edit', type: :feature do
  before do
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

  def denies_user_access(member)
    visit edit_event_membership_path(@event, member)

    expect(page.body).to have_css('div.alert.flash')
    expect(current_path).to eq(my_events_path)
  end

  def allows_person_editing(member)
    fill_in 'membership_person_attributes_firstname', with: 'Samuel'
    fill_in 'membership_person_attributes_lastname', with: 'Jackson'
    fill_in 'membership_person_attributes_email', with: 'sam@jackson.edu'
    uncheck 'membership_share_email'
    fill_in 'membership_person_attributes_url', with: 'http://sam.i.am'
    fill_in 'membership_person_attributes_affiliation', with: 'Hollywood'
    fill_in 'membership_person_attributes_department', with: 'Movies'
    fill_in 'membership_person_attributes_title', with: 'Actor'
    fill_in 'membership_person_attributes_research_areas', with: 'drama, fame'
    fill_in 'membership_person_attributes_biography', with: 'I did a thing.'

    click_button 'Update Member'

    person = Person.find(member.person_id)
    expect(person.name).to eq('Samuel Jackson')
    expect(person.affil_with_title).to eq('Hollywood, Movies — Actor')
    expect(person.url).to eq('http://sam.i.am')
    expect(person.biography).to eq('I did a thing.')
    expect(person.research_areas).to eq('drama, fame')
  end

  def allows_personal_info_editing(member)
    select 'Undergraduate Student',
           from: 'membership_person_attributes_academic_status'
    select 'Other', from: 'membership_person_attributes_gender'
    fill_in 'membership_person_attributes_phone', with: '123-456-7890'
    fill_in 'membership_person_attributes_address1', with: '1 Infinity Loop'
    fill_in 'membership_person_attributes_city', with: 'Cupertino'
    fill_in 'membership_person_attributes_region', with: 'CA'
    fill_in 'membership_person_attributes_postal_code', with: '95014'
    fill_in 'membership_person_attributes_country', with: 'Zimbabwe'
    fill_in 'membership_person_attributes_emergency_contact', with: 'Mom'
    fill_in 'membership_person_attributes_emergency_phone', with: '1234'
    fill_in 'membership_person_attributes_phd_year', with: '1987'

    click_button 'Update Member'

    person = Person.find(member.person_id)
    expect(person.academic_status).to eq('Undergraduate Student')
    expect(person.gender).to eq('O')
    expect(person.phone).to eq('123-456-7890')
    expect(person.address1).to eq('1 Infinity Loop')
    expect(person.emergency_contact).to eq('Mom')
    expect(person.emergency_phone).to eq('1234')
    expect(person.phd_year).to eq('1987')
  end

  def allows_membership_info_editing(member)
    select 'Organizer', from: 'membership_role'
    select 'Undecided', from: 'membership_attendance'

    click_button 'Update Member'

    membership = Membership.find(member.id)
    expect(membership.role).to eq('Organizer')
    expect(membership.attendance).to eq('Undecided')

    visit edit_event_membership_path(@event, member)
    allows_arrival_departure_editing(member)
  end

  def allows_billing_info_editing(member)
    expect(page).to have_field('membership_reviewed', checked: false)
    check 'membership_reviewed'
    fill_in 'membership_billing', with: 'SOS'
    uncheck 'membership_own_accommodation'
    fill_in 'membership_room', with: 'AB 123'
    expect(page).to have_field('membership_has_guest', checked: false)
    check 'membership_has_guest'
    fill_in 'membership_special_info', with: 'Very.'
    fill_in 'membership_staff_notes', with: 'Beware.'
    select 'Other', from: 'membership_person_attributes_gender'

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    expect(page.body).to have_css('div#profile-reviewed', text: 'Yes')
    expect(page.body).to have_css('div#profile-billing', text: 'SOS')
    expect(page.body).to have_css('div#profile-gender', text: 'O')
    expect(page.body).to have_css('div#profile-room', text: 'AB 123')
    expect(page.body).to have_css('div#profile-has-guest', text: 'Yes')
    expect(page.body).to have_css('div#profile-special-info', text: 'Very.')
    expect(page.body).to have_css('div#profile-staff-notes', text: 'Beware.')
  end

  def allows_arrival_departure_editing(member)
    arrives = (@event.start_date + 1.day).strftime('%Y-%m-%d')
    select "#{arrives}", from: 'membership_arrival_date'
    departs = (@event.end_date - 1.day).strftime('%Y-%m-%d')
    select departs, from: 'membership_departure_date'

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    arrival = (@event.start_date + 1.day).strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-arrival', text: arrival)
    departure = (@event.end_date - 1.day).strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-departure', text: departure)
  end

  def allows_extended_stays(member)
    arrival = (@event.start_date - 1.day).strftime('%Y-%m-%d')
    select arrival, from: 'membership_arrival_date'
    departure = (@event.end_date + 1.day).strftime('%Y-%m-%d')
    select departure, from: 'membership_departure_date'

    click_button 'Update Member'

    expect(page.body).not_to include('special permission required')
    arrival = (@event.start_date - 1.day).strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-arrival', text: arrival)
    departure = (@event.end_date + 1.day).strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-departure', text: departure)
  end

  def disallows_personal_info_editing
    field_name = 'membership_person_attributes_academic_status'
    expect(page.body).not_to have_field field_name
    expect(page.body).not_to have_field 'membership_person_attributes_gender'
    expect(page.body).not_to have_field 'membership_person_attributes_phone'
    expect(page.body).not_to have_field 'membership_person_attributes_address1'
    expect(page.body).not_to have_field 'membership_person_attributes_address2'
    expect(page.body).not_to have_field 'membership_person_attributes_address3'
    expect(page.body).not_to have_field 'membership_person_attributes_city'
    expect(page.body).not_to have_field 'membership_person_attributes_region'
    expect(page.body).not_to have_field 'membership_person_attributes_postal_code'
    expect(page.body).not_to have_field 'membership_person_attributes_country'
  end

  def disallows_hotel_fields
    expect(page.body).not_to have_field 'membership_reviewed'
    expect(page.body).not_to have_field 'membership_billing'
    expect(page.body).not_to have_field 'membership_room'
    expect(page.body).not_to have_field 'membership_has_guest'
    expect(page.body).not_to have_field 'membership_special_info'
    expect(page.body).not_to have_field 'membership_staff_notes'
  end

  def allows_organizer_notes(member)
    fill_in 'membership_org_notes', with: 'Testing'

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    expect(page.body).to have_css('div#profile-org-notes', text: 'Testing')
  end

  context 'As a not-logged in user' do
    it 'denies access' do
      visit edit_event_membership_path(@event, @participant)

      expect(page.body).to have_css('div.alert.flash')
      expect(current_path).to eq(new_user_session_path)
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    it 'denies access' do
      login_as @non_member_user, scope: :user
      denies_user_access(@participant)
    end
  end

  context "As a member of the event editing someone else's record" do
    it 'denies access' do
      login_as @participant_user, scope: :user
      denies_user_access(@organizer)
    end
  end

  context 'As a member of the event editing their own record' do
    before do
      login_as @participant_user, scope: :user
    end

    before :each do
      visit edit_event_membership_path(@event, @participant)
    end

    it 'allows access' do
      edit_path = edit_event_membership_path(@event, @participant)
      expect(current_path).to eq(edit_path)
    end

    it 'allows editing of person fields' do
      allows_person_editing(@participant)
    end

    it 'changing email signs out user' do
      @participant.person.email = Faker::Internet.email
      @participant_user.email = @participant.person.email
      @participant.save
      @participant_user.save

      visit edit_event_membership_path(@event, @participant)
      fill_in 'membership_person_attributes_email', with: 'new@email.com'

      click_button 'Update Member'

      expect(current_path).to eq(sign_in_path)
      expect(page.body).to have_css('div.alert-notice', text: 'Please verify')
    end

    it 'allows editing of personal info' do
      allows_personal_info_editing(@participant)
    end

    it 'allows editing of arrival & departure dates' do
      allows_arrival_departure_editing(@participant)
    end

    it 'does not allow travel dates outside of event dates' do
      legit_dates = [@event.start_date]
      while legit_dates.last != @event.end_date
        legit_dates << legit_dates.last + 1.day
      end

      legit_dates.map! { |d| d.strftime('%Y-%m-%d') }

      expect(page).to have_select 'membership_arrival_date', options: legit_dates
    end

    it 'disables role & attendance fields' do
      expect(page.body).not_to have_field 'membership_role'
      expect(page.body).not_to have_field 'membership_attendance'
    end

    it 'disregards non-numeric Ph.D year data' do
      @participant.person.phd_year = '1984'
      @participant.save
      fill_in :membership_person_attributes_phd_year, with: 'N/A'

      click_button 'Update Member'

      expect(Person.find(@participant.person_id).phd_year).to be_nil
    end

    it 'hides organizer notes' do
      expect(page.body).not_to have_field 'membership_org_notes'
    end

    it 'hides hotel & billing fields' do
      disallows_hotel_fields
    end

    it 'has no send invitation link' do
      expect(page.body).not_to have_link 'Send Invitation'
    end
  end

  context 'As an organizer of the event' do
    before do
      organizer_user = create(:user, email: @organizer.person.email,
                                            person: @organizer.person)
      login_as organizer_user, scope: :user
    end

    before :each do
      visit edit_event_membership_path(@event, @participant)
    end

    it 'allows access' do
      edit_path = edit_event_membership_path(@event, @participant)
      expect(current_path).to eq(edit_path)
    end

    it 'allows editing of person fields' do
      allows_person_editing(@participant)
    end

    it 'disallows editing of personal info' do
      disallows_personal_info_editing
    end

    it 'allows changing membership role' do
      select 'Backup Participant', from: 'membership_role'

      click_button 'Update Member'
      visit event_membership_path(@event, @participant)

      expect(page.body).to have_css('div#profile-role',
                                    text: 'Backup Participant')
    end

    it 'does not allow changing Participants to Organizer role' do
      select = find(:select, 'membership_role')
      expect(select).to have_selector(:option, 'Contact Organizer',
                                      disabled: true)
      expect(select).to have_selector(:option, 'Organizer', disabled: true)
      expect(select).to have_selector(:option, 'Participant', disabled: false)
      expect(select).to have_selector(:option, 'Backup Participant')
      expect(select).to have_selector(:option, 'Observer', disabled: false)
    end

    it 'does not allow changing roles of Organizers' do
      visit edit_event_membership_path(@event, @organizer)
      expect(page).not_to have_select('membership_role')
    end

    it 'allows changing attendance status' do
      select 'Declined', from: 'membership_attendance'

      click_button 'Update Member'
      visit event_membership_path(@event, @participant)

      expect(page.body).to have_css('div#profile-attendance', text: 'Declined')
    end

    it 'allows changing from Confirmed to Undecided or Declined' do
      expect(@participant.attendance).to eq('Confirmed')
      select = find(:select, 'membership_attendance')
      expect(select).to have_selector(:option, 'Confirmed', disabled: true)
      expect(select).to have_selector(:option, 'Invited', disabled: true)
      expect(select).to have_selector(:option, 'Undecided', disabled: false)
      expect(select).to have_selector(:option, 'Not Yet Invited', disabled: true)
      expect(select).to have_selector(:option, 'Declined', disabled: false)
    end

    it 'allows changing from Invited to Declined' do
      @participant.attendance = 'Invited'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).to have_selector(:option, 'Confirmed', disabled: true)
      expect(select).to have_selector(:option, 'Invited', disabled: true)
      expect(select).to have_selector(:option, 'Undecided', disabled: true)
      expect(select).to have_selector(:option, 'Not Yet Invited', disabled: true)
      expect(select).to have_selector(:option, 'Declined', disabled: false)
    end

    it 'allows changing from Undecided to Declined' do
      @participant.attendance = 'Undecided'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).to have_selector(:option, 'Confirmed', disabled: true)
      expect(select).to have_selector(:option, 'Invited', disabled: true)
      expect(select).to have_selector(:option, 'Undecided', disabled: true)
      expect(select).to have_selector(:option, 'Not Yet Invited', disabled: true)
      expect(select).to have_selector(:option, 'Declined', disabled: false)
    end

    it 'allows changing from Not Yet Invited to Declined' do
      @participant.attendance = 'Not Yet Invited'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).to have_selector(:option, 'Confirmed', disabled: true)
      expect(select).to have_selector(:option, 'Invited', disabled: true)
      expect(select).to have_selector(:option, 'Undecided', disabled: true)
      expect(select).to have_selector(:option, 'Not Yet Invited', disabled: true)
      expect(select).to have_selector(:option, 'Declined', disabled: false)
    end

    it 'disallows changing from Declined' do
      @participant.attendance = 'Declined'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).to have_selector(:option, 'Confirmed', disabled: true)
      expect(select).to have_selector(:option, 'Invited', disabled: true)
      expect(select).to have_selector(:option, 'Undecided', disabled: true)
      expect(select).to have_selector(:option, 'Not Yet Invited', disabled: true)
      expect(select).to have_selector(:option, 'Declined', disabled: true)
    end

    it 'disallows changing of travel dates' do
      expect(page.body).not_to have_field 'membership[arrival_date]'
      expect(page.body).not_to have_field 'membership[departure_date]'
    end

    it 'allows organizer notes' do
      allows_organizer_notes(@participant)
    end

    it 'hides hotel & billing fields' do
      disallows_hotel_fields
    end

    it 'has send invitation link' do
      expect(page.body).to have_link 'Send Invitation'
    end

    it 'has no send invitation link if role is Backup Participant' do
      @participant.role = 'Backup Participant'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      expect(page.body).not_to have_link 'Send Invitation'
      @participant.role = 'Participant'
      @participant.save
    end
  end

  context 'As a staff user at a different location' do
    it 'denies access' do
      @non_member_user.role = :staff
      @non_member_user.location = 'elsewhere'
      @non_member_user.save
      login_as @non_member_user, scope: :user
      visit edit_event_membership_path(@event, @participant)

      denies_user_access(@participant)
    end
  end

  context 'As a staff user at the same location' do
    before do
      @non_member_user.role = :staff
      @non_member_user.location = @event.location
      @non_member_user.save
      @participant = create(:membership, event: @event, has_guest: false,
                                         reviewed: false)
      login_as @non_member_user, scope: :user
    end

    before :each do
      visit edit_event_membership_path(@event, @participant)
    end

    it 'allows access' do
      edit_path = edit_event_membership_path(@event, @participant)
      expect(current_path).to eq(edit_path)
    end

    it 'allows editing of person fields' do
      allows_person_editing(@participant)
    end

    it 'allows editing of personal info' do
      allows_personal_info_editing(@participant)
    end

    it 'allows editing of membership info' do
      allows_membership_info_editing(@participant)
    end

    it 'allows editing of travel dates' do
      expect(page.body).to have_select 'membership[arrival_date]'
      expect(page.body).to have_select 'membership[departure_date]'
    end

    it 'allows changing travel dates to outside of event dates' do
      allows_extended_stays(@participant)
    end

    it 'hides organizer notes' do
      expect(page.body).not_to have_field 'membership_org_notes'
    end

    it 'allows editing of billing info' do
      allows_billing_info_editing(@participant)
    end

    it 'has send invitation link' do
      expect(page.body).to have_link 'Send Invitation'
    end

    it 'updates legacy database with changes' do
      lc = FakeLegacyConnector.new
      allow(SyncMembershipJob).to receive(:perform_later)

      fill_in :membership_staff_notes, with: 'Testing notes'
      click_button 'Update Member'
      expect(SyncMembershipJob).to have_received(:perform_later)
        .with(@participant.id)
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.role = :admin
      @non_member_user.save
      login_as @non_member_user, scope: :user
      @participant = create(:membership, event: @event, has_guest: false,
                                         reviewed: false)
    end

    before :each do
      visit edit_event_membership_path(@event, @participant)
    end

    it 'allows access' do
      edit_path = edit_event_membership_path(@event, @participant)
      expect(current_path).to eq(edit_path)
    end

    it 'allows editing of person fields' do
      allows_person_editing(@participant)
    end

    it 'allows editing of personal info' do
      allows_personal_info_editing(@participant)
    end

    it 'allows editing of arrival & departure dates' do
      allows_arrival_departure_editing(@participant)
    end

    it 'allows changing travel dates to outside of event dates' do
      allows_extended_stays(@participant)
    end

    it 'allows editing of membership info' do
      allows_membership_info_editing(@participant)
    end

    it 'has send invitation link' do
      expect(page.body).to have_link 'Send Invitation'
    end

    it 'allows organizer notes' do
      allows_organizer_notes(@participant)
    end

    it 'allows editing of billing info' do
      allows_billing_info_editing(@participant)
    end
  end
end
