# ./spec/features/membership_edit_spec.rb
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
    @other_person = create(:person)
  end

  after(:each) do
    Warden.test_reset!
  end

  def assign_participant_email_to_user
    @participant.person.email = Faker::Internet.email
    @participant.save
    @participant_user.email = @participant.person.email
    @participant_user.person_id = @participant.person_id
    @participant_user.skip_reconfirmation!
    @participant_user.save
  end


  def denies_user_access(member)
    visit edit_event_membership_path(@event, member)

    expect(page.body).to have_css('div.alert', text:
      'You need to sign in or sign up before continuing.')
    expect(current_path).to eq(my_events_path)
  end

  def access_denied(member)
    visit edit_event_membership_path(@event, member)
    expect(page.body).not_to have_css('div#profile-name',
                                      text: member.person.name)
    expect(page.body).to have_css('div.alert', text:
      'Access denied.')
    expect(current_path).to eq(my_events_path)
  end

  def allows_person_editing(member)
    fill_in 'membership_person_attributes_firstname', with: 'Samuel'
    fill_in 'membership_person_attributes_lastname', with: 'Jackson'
    fill_in 'membership_person_attributes_email', with: 'sam@jackson.edu'
    uncheck 'membership_share_email'
    check 'membership_share_email_hotel'
    fill_in 'membership_person_attributes_url', with: 'http://sam.i.am'
    fill_in 'membership_person_attributes_affiliation', with: 'Hollywood'
    fill_in 'membership_person_attributes_department', with: 'Movies'
    fill_in 'membership_person_attributes_title', with: 'Actor'
    fill_in 'membership_person_attributes_research_areas', with: 'drama, fame'
    fill_in 'membership_person_attributes_biography', with: 'I did a thing.'

    click_button 'Update Member'

    person = Person.find(member.person_id)
    expect(person.name).to eq('Samuel Jackson')
    expect(person.email).to eq('sam@jackson.edu')
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
    fill_in 'membership_person_attributes_country', with: 'Zimbabwe'
    fill_in 'membership_person_attributes_emergency_contact', with: 'Mom'
    fill_in 'membership_person_attributes_emergency_phone', with: '1234'
    fill_in 'membership_person_attributes_phd_year', with: '1987'

    click_button 'Update Member'

    person = Person.find(member.person_id)
    expect(person.academic_status).to eq('Undergraduate Student')
    expect(person.gender).to eq('O')
    expect(person.phone).to eq('123-456-7890')
    expect(person.emergency_contact).to eq('Mom')
    expect(person.emergency_phone).to eq('1234')
    expect(person.phd_year).to eq('1987')
  end

  def allows_country_region_editing(member)
    fill_in 'membership_person_attributes_country', with: 'Canada'
    fill_in 'membership_person_attributes_region', with: 'BC'

    click_button 'Update Member'

    person = Person.find(member.person_id)
    expect(person.country).to eq('Canada')
    expect(person.region).to eq('BC')
  end

  def allows_address_editing(member)
    fill_in 'membership_person_attributes_address1', with: '123 Privacy St.'
    fill_in 'membership_person_attributes_address2', with: 'Unit 6'
    fill_in 'membership_person_attributes_address3', with: 'Around back'
    fill_in 'membership_person_attributes_city', with: 'Privacyville'
    fill_in 'membership_person_attributes_region', with: 'AB'
    fill_in 'membership_person_attributes_country', with: 'Canada'
    fill_in 'membership_person_attributes_postal_code', with: 'X01 4Y3'

    click_button 'Update Member'

    person = Person.find(member.person_id)
    expect(person.address1).to eq('123 Privacy St.')
    expect(person.address2).to eq('Unit 6')
    expect(person.address3).to eq('Around back')
    expect(person.city).to eq('Privacyville')
    expect(person.region).to eq('AB')
    expect(person.country).to eq('Canada')
    expect(person.postal_code).to eq('X01 4Y3')
  end

  def does_not_have_address_fields
    expect(page.has_no_field?('membership_person_attributes_address1'))
    expect(page.has_no_field?('membership_person_attributes_address2'))
    expect(page.has_no_field?('membership_person_attributes_address3'))
    expect(page.has_no_field?('membership_person_attributes_city'))
    expect(page.has_no_field?('membership_person_attributes_postal_code'))
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
    fill_in 'membership_room_notes', with: 'Night-owl'
    expect(page).to have_field('membership[has_guest]', checked: false)
    check 'membership[has_guest]'
    fill_in 'membership_special_info', with: 'Very.'
    fill_in 'membership_staff_notes', with: 'Beware.'
    select 'Other', from: 'membership_person_attributes_gender'

    click_button 'Update Member'
    visit event_membership_path(@event, member)

    expect(page.body).to have_css('div#profile-reviewed', text: 'Yes')
    expect(page.body).to have_css('div#profile-billing', text: 'SOS')
    expect(page.body).to have_css('div#profile-gender', text: 'O')
    expect(page.body).to have_css('div#profile-room', text: 'AB 123')
    expect(page.body).to have_css('div#profile-room_notes', text: 'Night-owl')
    expect(page.body).to have_css('div#profile-has-guest', text: 1)
    expect(page.body).to have_css('div#profile-special-info', text: 'Very.')
    expect(page.body).to have_css('div#profile-staff-notes', text: 'Beware.')
  end

  def allows_rsvp_info_editing(member)
    member.own_accommodation = true
    member.special_info = 'Vegetarian'
    member.has_guest = false
    member.num_guests = 0
    member.save!

    visit edit_event_membership_path(@event, member)
    choose 'membership_own_accommodation_false'
    fill_in 'membership_special_info', with: 'Carnivore'
    check 'membership[has_guest]'
    fill_in 'membership_num_guests', with: '2'
    click_button 'Update Member'

    updated = Membership.find(member.id)
    expect(updated.own_accommodation).to be_falsey
    expect(updated.special_info).to eq('Carnivore')
    expect(updated.has_guest).to be_truthy
    expect(updated.num_guests).to eq(2)
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
    expect(page.body).not_to have_field 'membership_person_attributes_region'
    expect(page.body).not_to have_field 'membership_person_attributes_country'
  end

  def disallows_country_region_editing
    expect(page.body).not_to have_field 'membership_person_attributes_country'
    expect(page.body).not_to have_field 'membership_person_attributes_region'
  end

  def disallows_hotel_fields
    expect(page.body).not_to have_field 'membership_reviewed'
    expect(page.body).not_to have_field 'membership_billing'
    expect(page.body).not_to have_field 'membership_room'
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

      expect(page.body).to have_css('div.alert', text:
            'You need to sign in or sign up before continuing.')
      expect(current_path).to eq(new_user_session_path)
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    it 'denies access' do
      login_as @non_member_user, scope: :user
      access_denied(@participant)
    end
  end

  context "As a member of the event editing someone else's record" do
    it 'denies access' do
      login_as @participant_user, scope: :user
      access_denied(@organizer)
    end
  end

  context 'As a member of the event editing their own record' do
    before do
      login_as @participant_user, scope: :user
    end

    before :each do
      ActionMailer::Base.deliveries.clear
      visit edit_event_membership_path(@event, @participant)
    end

    it 'allows access' do
      edit_path = edit_event_membership_path(@event, @participant)
      expect(current_path).to eq(edit_path)
    end

    it 'allows editing of person fields' do
      allows_person_editing(@participant)
    end

    it 'allows editing of personal address fields' do
      allows_address_editing(@participant)
    end

    it 'allows editing of RSVP fields' do
      allows_rsvp_info_editing(@participant)
    end

    it 'if user sets num_guests to nil, sets num_guests to 0' do
      visit edit_event_membership_path(@event, @participant)
      fill_in 'membership_num_guests', with: nil
      uncheck 'membership[has_guest]'
      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.num_guests).to eq(0)
    end

    it 'if user checks has_guests, sets num_guests to 1' do
      @participant.num_guests = 0
      @participant.save
      visit edit_event_membership_path(@event, @participant)
      check 'membership[has_guest]'
      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.num_guests).to eq(1)
    end

    it 'if user unchecks has_guests, sets num_guests to 0' do
      @participant.num_guests = 2
      @participant.save
      visit edit_event_membership_path(@event, @participant)
      uncheck 'membership[has_guest]'
      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.num_guests).to eq(0)
    end

    it 'changing email signs out user and sends confirmation email' do
      assign_participant_email_to_user
      new_email = 'new@email.com'

      visit edit_event_membership_path(@event, @participant)
      fill_in 'membership_person_attributes_email', with: new_email

      click_button 'Update Member'

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to eq([new_email])
      expect(page.body).to have_css('div.alert-notice', text: 'Please verify')
      expect(current_path).to eq(sign_in_path)
    end

    it 'changing email to an email of another record with a matching name
         merges the person records, adding new form data'.squish do
      assign_participant_email_to_user
      other_person = create(:person,
                            firstname: @participant.person.firstname,
                             lastname: @participant.person.lastname,
                    emergency_contact: 'Me')
      new_email = other_person.email

      visit edit_event_membership_path(@event, @participant)
      fill_in 'membership_person_attributes_email', with: new_email
      fill_in 'membership_person_attributes_biography', with: 'Yes.'
      fill_in 'membership_person_attributes_emergency_contact', with: 'You'

      click_button 'Update Member'

      expect(Person.find_by_id(other_person.id)).to be_nil
      updated = Membership.find(@participant.id)
      expect(updated.person.email).to eq(new_email)
      expect(updated.person.emergency_contact).to eq('You')
      expect(updated.person.biography).to eq('Yes.')
    end

    it 'changing email to an email of another record with a different name
          updates original record, creates a new ConfirmEmailChange, and
          forwards to #email_change'.squish do
      assign_participant_email_to_user
      other_person = create(:person)
      old_email = @participant.person.email
      new_email = other_person.email

      visit edit_event_membership_path(@event, @participant)
      fill_in 'membership_person_attributes_email', with: new_email
      fill_in 'membership_person_attributes_biography', with: 'Yes.'
      fill_in 'membership_person_attributes_emergency_contact', with: 'Me'

      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.person.emergency_contact).to eq('Me')
      expect(updated.person.biography).to eq('Yes.')
      expect(updated.person.email).to eq(old_email)

      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).not_to eq 0
      active_job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(active_job[:job]).to eq(ConfirmEmailReplacementJob)

      confirmation = ConfirmEmailChange.find(active_job[:args].first)
      expect(confirmation.replace_email).to eq(old_email)
      expect(confirmation.replace_with_email).to eq(new_email)

      email_path = event_membership_email_change_path(@event, @participant)
      expect(current_path).to eq(email_path)
      expect(page.body).to have_text('there is an email conflict')
    end

    context '#email_change form' do
      before do
        assign_participant_email_to_user
        @other_person = create(:person)
        @old_email = @participant.person.email
        @new_email = @other_person.email

        visit edit_event_membership_path(@event, @participant)
        fill_in 'membership_person_attributes_email', with: @new_email
        click_button 'Update Member'
        email_path = event_membership_email_change_path(@event, @participant)
        expect(current_path).to eq(email_path)
        @confirm = ConfirmEmailChange.where(replace_person_id: @other_person.id,
                    replace_with_id: @participant.person_id).first
        expect(@confirm).not_to be_blank
      end

      it 'displays the correct emails and input forms' do
        expected_text = "There is another record in our database using
          #{@new_email}".squish
        expect(page).to have_text(expected_text)
        expect(page).to have_text("Verification code for #{@old_email}")
        expect(page).to have_text("Verification code for #{@new_email}")
        expect(page).to have_field('email_form[replace_email_code]')
        expect(page).to have_field('email_form[replace_with_email_code]')
        expect(page).to have_link('Cancel Email Change')
      end

      it 'validates confirmation codes' do
        fill_in 'email_form[replace_email_code]', with: @confirm.replace_code
        fill_in 'email_form[replace_with_email_code]', with: 'wrong code'
        click_button 'Submit Verification Codes'
        error_message = 'At least one of the submitted codes is invalid'
        expect(page).to have_text(error_message)

        fill_in 'email_form[replace_email_code]', with: 'wrong code'
        fill_in 'email_form[replace_with_email_code]',
          with: @confirm.replace_with_code
        click_button 'Submit Verification Codes'
        expect(page).to have_text(error_message)
      end

      it 'correct codes: sets confirmation = true' do
        fill_in 'email_form[replace_email_code]', with: @confirm.replace_code
        fill_in 'email_form[replace_with_email_code]',
                                                with: @confirm.replace_with_code
        click_button 'Submit Verification Codes'

        updated = ConfirmEmailChange.find(@confirm.id)
        expect(updated.confirmed).to be_truthy
      end

      it 'correct codes: merges updated person record into other record, with
        new email address' do
        fill_in 'email_form[replace_email_code]', with: @confirm.replace_code
        fill_in 'email_form[replace_with_email_code]',
                                                with: @confirm.replace_with_code
        click_button 'Submit Verification Codes'

        expect(Person.find_by_id(@other_person.id)).to be_blank
        updated = Person.find(@participant.person_id)
        expect(updated.email).to eq(@new_email)
      end

      it 'deletes ConfirmEmailChange if cancel button clicked' do
        click_link 'Cancel Email Change'
        expect(ConfirmEmailChange.find_by_id(@confirm.id)).to be_blank
        expect(current_path).to eq(event_membership_path(@participant.event,
                                                         @participant))
        expect(page).to have_text('Email change cancelled')
      end
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

    context '... who has not yet responded to an invitation' do
      before do
        @invitation = Invitation.new(membership: @participant, invited_by: 'x')
        @invitation.save
        visit edit_event_membership_path(@event, @participant)
      end

      after do
        @invitation.destroy
      end

      it 'denies access' do
        access_denied(@participant)
      end
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

    it 'disallows editing of country & region' do
      disallows_country_region_editing
    end

    it 'does not show address fields' do
      does_not_have_address_fields
    end

    it 'allows changing email to one taken by another record with
      the same name'.squish do
      @other_person.firstname = @participant.person.firstname
      @other_person.lastname = @participant.person.lastname
      @other_person.save

      fill_in 'membership_person_attributes_email', with: @other_person.email

      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.person.email).to eq(@other_person.email)
      expect(current_path).to eq(event_membership_path(@event, @participant))
    end

    it 'disallows changing email to one taken by another record with a
      different name'.squish do
      expect(@other_person.name).not_to eq(@participant.person.name)

      fill_in 'membership_person_attributes_email', with: @other_person.email

      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.person.email).not_to eq(@other_person.email)
      confirmation = ConfirmEmailChange
                              .where(replace_person_id: @participant.person_id)
      expect(confirmation).to be_blank
      expect(page.body).to have_css('div.alert-danger')
      expect(page.body).to have_text('Person email has already been taken')
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
      expect(select).to have_selector(:option, 'Confirmed')
      expect(select).not_to have_selector(:option, 'Invited')
      expect(select).to have_selector(:option, 'Undecided')
      expect(select).not_to have_selector(:option, 'Not Yet Invited')
      expect(select).to have_selector(:option, 'Declined')
    end

    it 'allows changing from Invited to Declined or Undecided' do
      @participant.attendance = 'Invited'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).not_to have_selector(:option, 'Confirmed')
      expect(select).to have_selector(:option, 'Invited')
      expect(select).to have_selector(:option, 'Undecided')
      expect(select).not_to have_selector(:option, 'Not Yet Invited')
      expect(select).to have_selector(:option, 'Declined')
    end

    it 'allows changing from Undecided to Declined or Invited' do
      @participant.attendance = 'Undecided'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).not_to have_selector(:option, 'Confirmed')
      expect(select).to have_selector(:option, 'Invited')
      expect(select).to have_selector(:option, 'Undecided')
      expect(select).not_to have_selector(:option, 'Not Yet Invited')
      expect(select).to have_selector(:option, 'Declined')
    end

    it 'allows changing from Not Yet Invited to Declined' do
      @participant.attendance = 'Not Yet Invited'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).not_to have_selector(:option, 'Confirmed')
      expect(select).not_to have_selector(:option, 'Undecided')
      expect(select).to have_selector(:option, 'Not Yet Invited')
      expect(select).to have_selector(:option, 'Declined')
    end

    it 'allows changing from Declined to Not Yet Invited' do
      @participant.attendance = 'Declined'
      @participant.save

      visit edit_event_membership_path(@event, @participant)

      select = find(:select, 'membership_attendance')
      expect(select).not_to have_selector(:option, 'Confirmed')
      expect(select).not_to have_selector(:option, 'Undecided')
      expect(select).to have_selector(:option, 'Not Yet Invited')
      expect(select).to have_selector(:option, 'Declined')
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
  end

  context 'As a staff user at a different location' do
    it 'denies access' do
      @non_member_user.role = :staff
      @non_member_user.location = 'elsewhere'
      @non_member_user.save
      login_as @non_member_user, scope: :user
      visit edit_event_membership_path(@event, @participant)

      access_denied(@participant)
    end
  end

  context 'As a staff user at the same location' do
    before do
      @non_member_user.role = :staff
      @non_member_user.location = @event.location
      @non_member_user.save
      @participant = create(:membership, event: @event, has_guest: false,
                            role:'Participant', reviewed: false)
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


    it 'allows editing of personal address' do
      allows_address_editing(@participant)
    end

    it 'allows editing of personal info' do
      allows_personal_info_editing(@participant)
    end

    it 'allows changing email to one taken by another record with
      the same name'.squish do
      @other_person.firstname = @participant.person.firstname
      @other_person.lastname = @participant.person.lastname
      @other_person.save

      fill_in 'membership_person_attributes_email', with: @other_person.email

      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.person.email).to eq(@other_person.email)
      expect(current_path).to eq(event_membership_path(@event, @participant))
    end

    it 'disallows changing email to one taken by another record with a
      different name'.squish do
      expect(@other_person.name).not_to eq(@participant.person.name)

      fill_in 'membership_person_attributes_email', with: @other_person.email

      click_button 'Update Member'

      updated = Membership.find(@participant.id)
      expect(updated.person.email).not_to eq(@other_person.email)
      confirmation = ConfirmEmailChange
                              .where(replace_person_id: @participant.person_id)
      expect(confirmation).to be_blank
      expect(page.body).to have_css('div.alert-danger')
      expect(page.body).to have_text('Person email has already been taken')
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

    it 'updates legacy database with changes' do
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

    it 'allows editing of personal address' do
      allows_address_editing(@participant)
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

    it 'allows organizer notes' do
      allows_organizer_notes(@participant)
    end

    it 'allows editing of billing info' do
      allows_billing_info_editing(@participant)
    end

    context 'changing email to one that is already associated to another record' do
      it 'merges the two Person records, keeping the best data' do
        assign_participant_email_to_user
        other_person = create(:person,
                              firstname: @participant.person.firstname,
                               lastname: @participant.person.lastname,
                               biography: nil,
                               research_areas: nil,
                               updated_at: DateTime.yesterday,
                      emergency_contact: 'Me')
        other_membership = create(:membership, person: other_person)
        old_email = @participant.person.email
        new_email = other_person.email

        visit edit_event_membership_path(@event, @participant)
        fill_in 'membership_person_attributes_email', with: new_email
        fill_in 'membership_person_attributes_biography', with: 'Yes.'
        fill_in 'membership_person_attributes_emergency_contact', with: 'You'
        click_button 'Update Member'

        expect(Person.find_by_id(other_person.id)).to be_nil
        expect(Person.find_by_email(old_email)).to be_nil
        updated = Membership.find(@participant.id)
        expect(updated.person.email).to eq(new_email)
        expect(updated.person.emergency_contact).to eq('You')
        expect(updated.person.biography).to eq('Yes.')
        other_updated = Membership.find(other_membership.id)
        expect(other_updated).not_to be_nil
        expect(other_updated.person_id).to eq(@participant.person_id)
      end

      it 'consolidates User records' do
        assign_participant_email_to_user
        other_person = create(:person,
                              firstname: @participant.person.firstname,
                               lastname: @participant.person.lastname,
                              biography: nil,
                         research_areas: nil,
                             updated_at: Time.now - 1.year,
                      emergency_contact: 'Me')

        old_email = @participant.person.email
        new_email = other_person.email
        create(:user, person: other_person, email: new_email)

        expect(User.find(@participant_user.id)).not_to be_nil
        expect(@participant_user.email).to eq(old_email)
        expect(@participant_user.person_id).to eq(@participant.person_id)

        visit edit_event_membership_path(@event, @participant)
        fill_in 'membership_person_attributes_email', with: new_email
        fill_in 'membership_person_attributes_biography', with: 'Yes.'
        fill_in 'membership_person_attributes_emergency_contact', with: 'You'
        click_button 'Update Member'

        expect(Person.find_by_id(other_person.id)).to be_nil
        expect(Person.find_by_email(old_email)).to be_nil

        expect(User.find_by_email(old_email)).to be_nil
        expect(User.find_by_person_id(other_person.id)).to be_nil

        user = User.find_by_email(new_email)
        expect(user).not_to be_nil
        expect(user.person_id).to eq(@participant.person_id)
      end
    end
  end
end
