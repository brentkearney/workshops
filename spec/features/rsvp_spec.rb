# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'RSVP', type: :feature do
  def reset_database
    Invitation.destroy_all
    Membership.destroy_all
    Person.destroy_all
    Event.destroy_all

    @event = create(:event, future: true)
    @person = create(:person, address1: '123 Street', city: 'City',
                     region: 'Region', postal_code: 'p0st4l', country: 'USA')
    @membership = create(:membership, event: @event, person: @person,
                         attendance: 'Invited')
    @invitation = create(:invitation, membership: @membership)
  end

  before do
    @lc = FakeLegacyConnector.new
    allow(LegacyConnector).to receive(:new).and_return(@lc)

    reset_database
  end

  before :each do
    visit rsvp_otp_path(@invitation.code)
  end

  it 'welcomes the user' do
    expect(current_path).to eq(rsvp_otp_path(@invitation.code))
    expect(page.body).to have_text("Dear #{@person.dear_name}:")
  end

  it 'displays the event name and date' do
    expect(page.body).to have_text(@event.name)
    expect(page.body).to have_text(@event.dates(:long))
  end

  it 'has yes, no, maybe buttons' do
    expect(page).to have_link('Yes')
    expect(page).to have_link('No')
    expect(page).to have_link('Maybe')
  end

  context 'Error conditions' do
    it 'past events' do
      @event.start_date = Time.zone.today.last_year
      @event.end_date = Time.zone.today.last_year + 5.days
      @event.save!

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('You cannot RSVP for past events')
    end

    it 'expired invitations' do
      @invitation.update_columns(expires: Date.today.last_year)

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('This invitation code is expired')
      @invitation.expires = Date.today.next_year
      @invitation.save
    end

    it 'non-existent invitations' do
      response = {'denied' => 'Invalid code'}
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(123)

      expect(page).to have_text('Invalid code')
    end

    it 'event code missing from legacy invitation record' do
      response = { 'otp_id' => '123', 'legacy_id' => '321',
                         'event_code' => '', 'attendance' => 'Invited' }
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(123)

      expect(page).to have_text('No event associated')
    end

    it 'person_id missing from legacy invitation record' do
      response = { 'otp_id' => '123', 'legacy_id' => '',
                   'event_code' => @event.code, 'attendance' => 'Invited' }
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(123)

      expect(page).to have_text('No person associated')
    end

    it 'participant not invited' do
      @membership.attendance = 'Not Yet Invited'
      @membership.save

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text("The event's organizers have not yet
        invited you".squish)
    end

    it 'participant already declined' do
      @membership.attendance = 'Declined'
      @membership.save

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('You have already declined an invitation')
    end

    it 'non-existent membership record' do
      @membership.destroy
      @person.legacy_id = '321'
      @person.save
      response = { 'otp_id' => '123', 'legacy_id' => '321',
                   'event_code' => @event.code, 'attendance' => 'Invited' }
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('Error finding membership')
    end

    it 'non-existent person record' do
      @person.destroy
      response = { 'otp_id' => '123', 'legacy_id' => '321',
                   'event_code' => @event.code, 'attendance' => 'Invited' }
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('Error finding person record')
    end

    it 'non-existent event record' do
      code = @event.code
      @event.destroy
      response = { 'otp_id' => '123', 'legacy_id' => '321',
                   'event_code' => code, 'attendance' => 'Invited' }
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('Error finding event record')
    end
  end

  context 'User says No' do
    before do
      reset_database
    end

    it 'presents a "message to the organizer" form' do
      visit rsvp_otp_path(@invitation.code)
      click_link 'No'
      expect(current_path).to eq(rsvp_no_path(@invitation.code))

      organizer_name = @event.organizer.name
      expect(page).to have_text(organizer_name)
      expect(page).to have_field("rsvp[organizer_message]")
    end

    context 'after the "Decline Attendance" button' do
      before do
        person = @invitation.membership.person
        person.affiliation = nil
        person.save
        @args = { 'attendance_was' => 'Invited',
                  'attendance' => 'Declined',
                  'organizer_message' => '' }
      end

      it 'queues background task for emailing organizer with message' do
        allow(EmailOrganizerNoticeJob).to receive(:perform_later).once
        visit rsvp_no_path(@invitation.code)
        fill_in 'rsvp[organizer_message]', with: "Sorry I can't make it!"
        click_button 'Decline Attendance'

        @args['organizer_message'] = "Sorry I can't make it!"
        expect(EmailOrganizerNoticeJob).to have_received(:perform_later).once
          .with(@invitation.membership.id, @args)
      end

      it 'says thanks' do
        visit rsvp_no_path(@invitation.code)
        click_button 'Decline Attendance'
        expect(page).to have_text('Thank you')
      end

      it 'declines membership' do
        visit rsvp_no_path(@invitation.code)
        click_button 'Decline Attendance'
        expect(Membership.find(@membership.id).attendance).to eq('Declined')
      end

      it 'destroys invitation' do
        visit rsvp_no_path(@invitation.code)
        click_button 'Decline Attendance'
        expect(Invitation.where(id: @invitation.id)).to be_empty
      end

      it 'forwards to feedback form, with flash message' do
        visit rsvp_no_path(@invitation.code)
        click_button 'Decline Attendance'
        expect(current_path).to eq(rsvp_feedback_path(@membership.id))
        expect(page.body).to have_css('div.alert', text:
          'Your attendance status was successfully updated. Thanks for your
          reply!'.squish)
      end

      it 'updates legacy database' do

        allow(SyncMembershipJob).to receive(:perform_later)
        reset_database

        visit rsvp_no_path(@invitation.code)
        click_button 'Decline Attendance'

        expect(SyncMembershipJob).to have_received(:perform_later)
          .with(@membership.id)
      end
    end
  end

  context 'User says Maybe' do
    before do
      reset_database
      visit rsvp_otp_path(@invitation.code)
      click_link "Maybe"
    end

    it 'says thanks' do
      expect(page).to have_text('Thanks')
    end

    it 'presents a "message to the organizer" form' do
      organizer_name = @event.organizer.name
      expect(page).to have_text(organizer_name)
      expect(page).to have_field("rsvp_organizer_message")
    end

    context 'after the "Send Reply" button' do
      before do
        reset_database
        @args = { 'attendance_was' => 'Invited',
                  'attendance' => 'Undecided',
                  'organizer_message' => '' }
      end

      it 'includes message in the organizer notice' do
        allow(EmailOrganizerNoticeJob).to receive(:perform_later).once
        visit rsvp_maybe_path(@invitation.code)
        fill_in "rsvp_organizer_message", with: 'I might be there'
        click_button "commit"

        @args['organizer_message'] = 'I might be there'
        expect(EmailOrganizerNoticeJob).to have_received(:perform_later).once
          .with(@invitation.membership.id, @args)
      end

      it 'changes membership attendance to Undecided' do
        visit rsvp_maybe_path(@invitation.code)
        click_button "commit"
        expect(Membership.find(@membership.id).attendance).to eq('Undecided')
      end

      it 'forwards to feedback form, with flash message' do
        visit rsvp_maybe_path(@invitation.code)
        click_button "commit"

        expect(current_path).to eq(rsvp_feedback_path(@membership.id))
        expect(page.body).to have_css('div.alert', text:
          'Your attendance status was successfully updated. Thanks for your
          reply!'.squish)
      end

      it 'updates legacy database' do
        visit rsvp_maybe_path(@invitation.code)
        click_button "commit"

        allow(SyncMembershipJob).to receive(:perform_later)
        reset_database

        visit rsvp_maybe_path(@invitation.code)
        click_button 'commit'

        expect(SyncMembershipJob).to have_received(:perform_later)
          .with(@membership.id)
      end
    end
  end

  context 'User says Yes' do
    context 'Confirm Email' do
      before do
        reset_database
        allow(SyncMember).to receive(:new).with(@membership, is_rsvp: true)
        @rsvp = RsvpForm.new(@invitation)
        visit rsvp_otp_path(@invitation.code)
        click_link "Yes"
      end

      it 'syncs membership with legacy db' do
        expect(SyncMember).to have_received(:new).with(@membership, is_rsvp: true)
      end

      it 'presents email confirmation form' do
        expect(page).to have_field('email_form_person_email')
      end

      it 'validates email format' do
        fill_in 'email_form_person_email', with: 'foo'
        click_button('Continue')
        expect(page.body).to have_text('Email is invalid')
      end

      it 'clicking Continue goes to #yes' do
        click_button('Continue')
        expect(current_path).to eq(rsvp_yes_path(@invitation.code))
      end

      it 'clicking Continue goes to #yes-online, if the event is online' do
        event = @invitation.membership.event
        event.event_format = 'Online'
        event.save

        visit rsvp_otp_path(@invitation.code)
        click_link "Yes"
        click_button('Continue')

        expect(current_path).to eq(rsvp_yes_online_path(@invitation.code))
      end

      it "clicking Continue goes to #yes-online, if member's role is virtual" do
        member = @invitation.membership
        member.role = 'Virtual Participant'
        member.save!

        visit rsvp_otp_path(@invitation.code)
        click_link "Yes"
        click_button('Continue')

        expect(current_path).to eq(rsvp_yes_online_path(@invitation.code))
      end

      it 'entering a new email updates the person record' do
        person = @membership.person
        expect(person.email).not_to eq('foo@bar.com')

        fill_in 'email_form_person_email', with: 'foo@bar.com'
        click_button('Continue')

        expect(Person.find(person.id).email).to eq('foo@bar.com')
        expect(current_path).to eq(rsvp_yes_path(@invitation.code))
      end

      it 'entering email of another record with the same name merges records' do
        person = @membership.person
        expect(person.email).not_to eq('new@email.com')
        other_person = create(:person, email: 'new@email.com',
                        lastname: person.lastname, firstname: person.firstname)

        fill_in 'email_form_person_email', with: 'new@email.com'
        click_button('Continue')

        person = Person.find_by_id(person.id)
        other_person = Person.find_by_id(other_person.id)
        expect(other_person).to be_nil unless person.nil?
        expect(person).to be_nil unless other_person.nil?

        merged_person = person.nil? ? other_person : person
        expect(Membership.find(@membership.id).person).to eq(merged_person)
        expect(current_path).to eq(rsvp_yes_path(@invitation.code))
      end
    end

    context 'Email Conflict' do
      before do
        reset_database
        @other_person = create(:person, email: 'foo@bar.com')
        allow(SyncMember).to receive(:new).with(@membership, is_rsvp: true)
        expect(@membership.person.email).not_to eq('foo@bar.com')

        visit rsvp_email_path(@invitation.code)
        fill_in 'email_form_person_email', with: 'foo@bar.com'
        click_button('Continue')
      end

      it 'creates a ConfirmEmailChange record' do
        expect(@person.pending_replacement?).to be_truthy
      end

      it 'enques background job to email confirmation codes' do
        ActiveJob::Base.queue_adapter = :test
        expect {
          ConfirmEmailReplacementJob.perform_later
        }.to have_enqueued_job(ConfirmEmailReplacementJob)
      end

      it 'shows fields for confirmation codes' do
        expect(page).to have_field('email_form[replace_email_code]')
        expect(page).to have_field('email_form[replace_with_email_code]')
      end

      it 'validates codes' do
        fill_in 'email_form[replace_email_code]', with: '1234'
        click_button("Submit Verification Codes")
        expect(page).to have_text('one of the submitted codes is invalid')
        expect(current_path).to eq(rsvp_confirm_email_path(otp: @invitation.code))
      end

      it 'entering valid codes merges person records' do
        person = @membership.person
        c = ConfirmEmailChange.last
        fill_in 'email_form[replace_email_code]', with: c.replace_code
        fill_in 'email_form[replace_with_email_code]', with: c.replace_with_code
        click_button("Submit Verification Codes")

        expect(Person.find_by_id(person.id)).to be_nil
        updated = Membership.find(@membership.id).person
        expect(updated).to eq(@other_person)
        expect(updated.email).to eq('foo@bar.com')
        expect(current_path).to eq(rsvp_yes_path(@invitation.code))
        expect(page).to have_text('E-mail updated')
      end

      it 'online events redirect to yes_online_path instead' do
        event = @invitation.membership.event
        event.event_format = 'Online'
        event.save

        person = @membership.person
        c = ConfirmEmailChange.last
        fill_in 'email_form[replace_email_code]', with: c.replace_code
        fill_in 'email_form[replace_with_email_code]', with: c.replace_with_code
        click_button("Submit Verification Codes")

        expect(Person.find_by_id(person.id)).to be_nil
        updated = Membership.find(@membership.id).person
        expect(updated).to eq(@other_person)
        expect(updated.email).to eq('foo@bar.com')
        expect(current_path).to eq(rsvp_yes_online_path(@invitation.code))
        expect(page).to have_text('E-mail updated')
      end
    end

    context 'After email confirmed' do
      def has_person_profile_fields
        expect(page).to have_field('rsvp_person_firstname')
        expect(page).to have_field('rsvp_person_lastname')
        expect(page).to have_field('rsvp_person_gender')
        expect(page).to have_field('rsvp_person_affiliation')
        expect(page).to have_field('rsvp_person_email', disabled: true)
        expect(page).to have_field('rsvp_membership_share_email')
        expect(page).to have_field('rsvp_person_url')
        expect(page).to have_field('rsvp_person_country')
        expect(page).to have_field('rsvp_person_biography')
        expect(page).to have_field('rsvp_person_research_areas')
      end

      def has_mailing_address_fields
        expect(page).to have_field('rsvp_person_address1')
        expect(page).to have_field('rsvp_person_address2')
        expect(page).to have_field('rsvp_person_address3')
        expect(page).to have_field('rsvp_person_city')
        expect(page).to have_field('rsvp_person_region')
        expect(page).to have_field('rsvp_person_country')
        expect(page).to have_field('rsvp_person_postal_code')
      end

      def has_no_mailing_address_fields
        expect(page).not_to have_field('rsvp_person_address1')
        expect(page).not_to have_field('rsvp_person_address2')
        expect(page).not_to have_field('rsvp_person_address3')
        expect(page).not_to have_field('rsvp_person_city')
        expect(page).not_to have_field('rsvp_person_postal_code')
      end

      def has_other_fields
        expect(page).to have_text(@rsvp.privacy_notice)

        expect(page).to have_css('span#revisit-note',
                  text: 'You can update this information')
        expect(page).to have_link(href: invitations_new_path(@event.code))
        expect(page).to have_link('membership profile', href: event_membership_path(@event, @membership))
      end

      def has_message_to_organizer_field
        organizer_name = @event.organizer.name
        expect(page).to have_text(organizer_name)
        expect(page).to have_field("rsvp_organizer_message")
      end

      def persists_organizer_message
        fill_in 'rsvp_organizer_message', with: 'Hi Org!'
        fill_in 'rsvp_person_firstname', with: ''

        click_button 'Confirm Attendance'

        expect(page.body).to have_text("Firstname can't be blank")
        expect(page).to have_css('textarea#rsvp_organizer_message',
          text: 'Hi Org!')
      end

      def persists_previous_staff_data
        @membership.staff_notes = 'Test note'
        @membership.room = 'Room 6'
        @membership.stay_id = 'ABC123'
        @membership.save

        fill_in 'rsvp_organizer_message', with: 'Hi Org!'
        click_button 'Confirm Attendance'

        updated_membership = Membership.find(@membership.id)
        expect(updated_membership.staff_notes).to eq('Test note')
        expect(updated_membership.room).to eq('Room 6')
        expect(updated_membership.stay_id).to eq('ABC123')
      end

      def fails_address_field_validation(yes_form_path)
        fill_in "rsvp_person_address1", with: ''
        fill_in "rsvp_person_address2", with: ''
        fill_in "rsvp_person_address3", with: ''
        fill_in "rsvp_person_city", with: ''
        fill_in "rsvp_person_region", with: ''
        fill_in "rsvp_person_postal_code", with: ''

        click_button 'Confirm Attendance'

        expect(current_path).to eq(yes_form_path)
        expect(page.body).to have_text('address fields cannot be blank')
      end

      def does_not_require_region
        fill_in "rsvp_person_region", with: ''
        fill_in "rsvp_person_country", with: 'Spain'

        click_button 'Confirm Attendance'

        expect(Person.find(@membership.person_id).country).to eq('Spain')
      end

      def requires_region(form_path)
        fill_in "rsvp_person_region", with: ''
        fill_in "rsvp_person_country", with: 'Canada'

        click_button 'Confirm Attendance'

        expect(current_path).to eq(form_path)
        failed = 'region field cannot be blank'
        expect(page.body).to have_text(failed)
      end

      def saves_address
        fill_in "rsvp_person_address1", with: '123 Street'
        fill_in "rsvp_person_address2", with: 'Unit 6'
        fill_in "rsvp_person_address3", with: 'in the alley'
        fill_in "rsvp_person_city", with: 'Baltimore'
        fill_in "rsvp_person_region", with: 'MD'

        click_button 'Confirm Attendance'

        updated = Person.find(@membership.person_id)
        expect(updated.address1).to eq('123 Street')
        expect(updated.address2).to eq('Unit 6')
        expect(updated.address3).to eq('in the alley')
        expect(updated.city).to eq('Baltimore')
        expect(updated.region).to eq('MD')
      end

      def submit_form(yes_form_path)
        @args = { 'attendance_was' => 'Invited',
                  'attendance' => 'Confirmed',
                  'organizer_message' => '' }
        allow(EmailParticipantConfirmationJob).to receive(:perform_later)
        allow(EmailOrganizerNoticeJob).to receive(:perform_later)
        visit yes_form_path
        fill_in "rsvp_organizer_message", with: 'Excited to attend!'
        fill_in 'rsvp_person_url', with: 'http://foo.com'
        click_button 'Confirm Attendance'
      end

      def check_saved_person_data
        expect(Person.find(@membership.person_id).url).to eq('http://foo.com')
      end

      def attendance_is_confirmed
        expect(Membership.find(@membership.id).attendance).to eq('Confirmed')
      end

      def includes_organizer_message
        @args['organizer_message'] = 'Excited to attend!'
        expect(EmailOrganizerNoticeJob).to have_received(:perform_later)
          .with(@invitation.membership.id, @args)
      end

      def sends_confirmation_email
        expect(EmailParticipantConfirmationJob)
          .to have_received(:perform_later).with(@membership.id)
      end

      def destroys_invitation
        expect(Invitation.where(id: @invitation.id)).to be_empty
      end

      def forwards_to_feedback
        expect(current_path).to eq(rsvp_feedback_path(@membership.id))
        expect(page.body).to have_css('div.alert', text:
          'Your attendance status was successfully updated. Thanks for your
          reply!'.squish)
      end

      def updates_legacy_database
        allow(SyncMembershipJob).to receive(:perform_later)
        reset_database
        allow(SyncMember).to receive(:new).with(@membership, is_rsvp: true)

        visit rsvp_yes_path(@invitation.code)
        click_button 'Confirm Attendance'

        expect(SyncMembershipJob).to have_received(:perform_later)
          .with(@membership.id)
      end

      def links_to_new_account
        expect(User.find_by_email(@membership.person.email)).to be_nil
        expect(page).to have_link('registering an account',
                                   href: new_user_registration_path)
      end

      def does_not_link_to_register(yes_path)
        person = @membership.person
        user = create(:user, person: person, email: person.email)
        expect(User.find_by_email(person.email)).not_to be_nil

        visit yes_path

        expect(page).not_to have_link('registering an account',
                                       href: new_user_registration_path)
      end

      context 'For in-person events' do
        before do
          reset_database
          @rsvp = RsvpForm.new(@invitation)
          visit rsvp_yes_path(@invitation.code)
        end

        it 'asks if they intend to attend virtually (for hybrid events)' do
          expect(page.body).to have_text('If you plan to attend this event
                                          online'.squish)
          expect(page).to have_link('Participate Virtually',
                             href: rsvp_yes_online_path(@invitation.code))
        end

        it 'has a personal profile form' do
          has_person_profile_fields()
          expect(page).to have_field('rsvp_person_gender')
          expect(page).to have_field('rsvp_person_phone')
          expect(page).to have_field('rsvp_person_emergency_contact')
          expect(page).to have_field('rsvp_person_emergency_phone')
        end

        it 'has arrival and departure date section' do
          expect(page).to have_field('rsvp_membership_arrival_date')
          expect(page).to have_field('rsvp_membership_departure_date')
        end

        it 'arrival & departure default to event start & end' do
          expect(page).to have_select('rsvp[membership][arrival_date]',
            selected: @event.start_date.strftime("%A, %b %-d, %Y"))
          expect(page).to have_select('rsvp[membership][departure_date]',
            selected: @event.end_date.strftime("%A, %b %-d, %Y"))
        end

        it 'has guests fields' do
          expect(page).to have_text(@rsvp.guests_intro)
          expect(page).to have_field('rsvp_membership_has_guest')
          expect(page).to have_field('rsvp_membership_guest_disclaimer')
        end

        it 'has special info/food field' do
          expect(page).to have_text(@rsvp.special_intro)
          expect(page).to have_field('rsvp_membership_special_info')
        end

        it 'has privacy notice, come back to edit instructions' do
          has_other_fields()
        end

        it 'persists the organizer message through form validation' do
          persists_organizer_message()
        end

        it 'persists staff attributes from before RSVP' do
          persists_previous_staff_data()
        end

        it 'validates if country is NOT North American and region is blank' do
          does_not_require_region()
        end

        it 'fails validation if country is North American and region blank' do
          requires_region(rsvp_yes_path(@invitation.code))
        end

        it 'includes "Grants" field if country is Canada' do
          fill_in "rsvp_person_country", with: 'Canada'
          fill_in "rsvp_person_region", with: 'Alberta'

          expect(page).to have_field('rsvp_person_grants')

          GetSetting.grant_list.each do |grant|
            expect(page).to have_text "#{grant.first}"
          end
        end

        it 'if participant has no account, links to register new account' do
          links_to_new_account()
        end

        it 'if participant already has account, does not link to register' do
          does_not_link_to_register(rsvp_yes_path(@invitation.code))
        end

        context 'user is an organizer' do
          before do
            @membership.role = 'Contact Organizer'
            @membership.save
            visit rsvp_yes_path(@invitation.code)
          end

          after do
            @membership.role = 'Participant'
            @membership.save
          end

          it 'has a mailing address section' do
            has_mailing_address_fields()
          end

          it 'skips the "message to organizer" form' do
            expect(page).not_to have_field("rsvp_organizer_message")
          end

          it 'fails validation if address data is blank' do
            fails_address_field_validation(rsvp_yes_path(@invitation.code))
          end

          it 'saves address data' do
            saves_address()
          end
        end # user is organizer

        context 'user is not an organizer' do
          it 'has no mailing address section' do
            has_no_mailing_address_fields()
          end

          it 'has "message to the organizer" field' do
            has_message_to_organizer_field()
          end
        end # user is not organizer

        context 'After submitting the form' do
          before do
            submit_form(rsvp_yes_path(@invitation.code))
          end

          it 'saves person data' do
            check_saved_person_data()
          end

          it 'changes membership attendance to confirmed' do
            attendance_is_confirmed()
          end

          it 'includes message in the organizer notice' do
            includes_organizer_message
          end

          it 'sends confirmation email to participant via background job' do
            sends_confirmation_email()
          end

          it 'destroys invitation' do
            destroys_invitation()
          end

          it 'forwards to feedback form, with flash message' do
            forwards_to_feedback()
          end

          it 'updates legacy database' do
            updates_legacy_database()
          end
        end # After submitting the form
      end # for in-person events


      context 'For Online events' do
        before do
          event = @invitation.membership.event
          event.event_format = 'Online'
          event.save
          @rsvp = RsvpForm.new(@invitation)
          visit rsvp_yes_online_path(@invitation.code)
        end

        it 'has a minimal personal profile form' do
          has_person_profile_fields()
        end

        it 'does not have arrival and departure date sections' do
          expect(page).not_to have_field('rsvp_membership_arrival_date')
          expect(page).not_to have_field('rsvp_membership_departure_date')
        end

        it 'does not have guests fields' do
          expect(page).not_to have_field('rsvp_membership_has_guest')
          expect(page).not_to have_field('rsvp_membership_guest_disclaimer')
        end

        it 'does not have special info/food field' do
          expect(page).not_to have_field('rsvp_membership_special_info')
        end

        it 'has privacy notice, come back to edit instructions' do
          has_other_fields()
        end

        it 'persists the organizer message through form validation' do
          persists_organizer_message()
        end

        it 'persists staff attributes from before RSVP' do
          persists_previous_staff_data()
        end

        it 'validates if country is NOT North American and region is blank' do
          does_not_require_region()
        end

        it 'fails validation if country is North American and region blank' do
          requires_region(rsvp_yes_online_path(@invitation.code))
        end

        it 'if participant has no account, links to register new account' do
          links_to_new_account()
        end

        it 'if participant already has account, does not link to register' do
          does_not_link_to_register(rsvp_yes_online_path(@invitation.code))
        end

        it "changes the participant's role to Virtual Participant" do
          membership = @invitation.membership
          membership.role = 'Participant'
          membership.save

          visit rsvp_yes_online_path(@invitation.code)
          click_button('Confirm Attendance')

          updated = Membership.find(membership.id)
          expect(updated.role).to eq('Virtual Participant')
        end

        context 'user is an organizer' do
          before do
            @membership.role = 'Contact Organizer'
            @membership.save
            visit rsvp_yes_online_path(@invitation.code)
          end

          after do
            @membership.role = 'Participant'
            @membership.save
          end

          it 'has a mailing address section' do
            has_mailing_address_fields()
          end

          it 'skips the "message to organizer" form' do
            expect(page).not_to have_field("rsvp_organizer_message")
          end

          it 'fails validation if address data is blank' do
            fails_address_field_validation(rsvp_yes_online_path(@invitation.code))
          end

          it 'saves address data' do
            saves_address()
          end
        end # user is organizer

        context 'user is not an organizer' do
          it 'has no mailing address section' do
            has_no_mailing_address_fields()
          end

          it 'has "message to the organizer" field' do
            has_message_to_organizer_field()
          end
        end # user is not organizer

        context 'After submitting the form' do
          before do
            submit_form(rsvp_yes_online_path(@invitation.code))
          end

          it 'saves person data' do
            check_saved_person_data()
          end

          it 'changes membership attendance to confirmed' do
            attendance_is_confirmed()
          end

          it 'includes message in the organizer notice' do
            includes_organizer_message
          end

          it 'sends confirmation email to participant via background job' do
            sends_confirmation_email()
          end

          it 'destroys invitation' do
            destroys_invitation()
          end

          it 'forwards to feedback form, with flash message' do
            forwards_to_feedback()
          end

          it 'updates legacy database' do
            updates_legacy_database()
          end
        end # After submitting the form
      end # for online events
    end # After email confirmed
  end

  context 'Feedback Form' do
    before :each do
      reset_database
      allow(EmailSiteFeedbackJob).to receive(:perform_later)
      visit rsvp_feedback_path(@invitation.membership_id)
    end

    def fill_in_feedback_from(msg)
      fill_in 'feedback_message', with: msg
      click_button 'Send Feedback'
    end

    it 'sends feedback email if user enters feedback text' do
      fill_in_feedback_from('Testing feedback form')

      expect(EmailSiteFeedbackJob).to have_received(:perform_later)
        .with('RSVP', @invitation.membership.id, 'Testing feedback form')
    end

    it 'does not send email if no text is entered' do
      fill_in_feedback_from('')
      expect(EmailSiteFeedbackJob).not_to have_received(:perform_later)
    end
  end
end


