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
    fill_in 'membership_person_attributes_research_areas', with: 'drama, cash'
    fill_in 'membership_person_attributes_biography', with: 'I did a thing.'

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    expect(page.body).to have_css('div#profile-name', text: 'Samuel Jackson')
    expect(page.body).to have_css('div#profile-affil',
                                  text: 'Hollywood, Movies — Actor')
    expect(page.body).to have_css('div#profile-url', text: 'http://sam.i.am')
    expect(page.body).to have_css('div#profile-bio', text: 'I did a thing.')
    expect(page.body).to have_css('div#profile-research', text: 'drama, cash')
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

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    expect(page.body).to have_css('div#profile-academic-status',
                                  text: 'Undergraduate Student')
    expect(Person.find(member.person.id).gender).to eq('O')
    expect(page.body).to have_css('div#profile-phone', text: '123-456-7890')
    expect(page.body).to have_css('div#profile-address',
      text: "\n      1 Infinity Loop\nCupertino, CA  95014\nZimbabwe\n    ")
  end

  def allows_arrival_departure_editing(member)
    arrival = (@event.start_date + 1.day).strftime('%Y-%m-%d')
    fill_in 'arrival_date', with: arrival
    departure = (@event.end_date - 1.day).strftime('%Y-%m-%d')
    fill_in 'departure_date', with: departure

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    arrival = (@event.start_date + 1.day).strftime('%b %-d, %Y')
    expect(page.body).to have_css('div#profile-arrival', text: arrival)
    departure = (@event.end_date - 1.day).strftime('%b %-d, %Y')
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

    it 'allows editing of personal info' do
      allows_personal_info_editing(@participant)
    end

    it 'allows editing of arrival & departure dates' do
      allows_arrival_departure_editing(@participant)
    end

    it 'disables other event membership fields'
      # expect(page.body).not_to have_field 'membership_role'
      # expect(page.body).not_to have_field 'membership_attendance'

    it 'hides organizer notes' do
      expect(page.body).not_to have_field 'membership_org_notes'
    end

    it 'hides hotel & billing fields' do
      disallows_hotel_fields
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

    it 'allows limited editing of membership feilds'

    it 'allows organizer notes' do
      allows_organizer_notes(@participant)
    end

    it 'hides hotel & billing fields' do
      disallows_hotel_fields
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

    it 'allows editing of all membership info'

    it 'hides organizer notes' do
      expect(page.body).not_to have_field 'membership_org_notes'
    end

    it 'allows editing of all billing info'
  end

  context 'As an admin user' do
    before do
      @non_member_user.role = :admin
      @non_member_user.save
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

    it 'allows editing of arrival & departure dates' do
      allows_arrival_departure_editing(@participant)
    end

    it 'allows editing of all membership info'

    it 'allows organizer notes' do
      allows_organizer_notes(@participant)
    end

    it 'allows editing of all billing info'
  end
end
