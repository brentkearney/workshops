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
    allow(SyncEventMembersJob).to receive(:perform_later).with(@event.id)
  end

  before do
    @lc = FakeLegacyConnector.new
    allow(LegacyConnector).to receive(:new).and_return(@lc)

    reset_database
  end

  before :each do
    visit rsvp_otp_path(@invitation.code)
  end

  it 'syncs event membership data' do
    expect(SyncEventMembersJob).to have_received(:perform_later).with(@event.id)
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
      @event.start_date = Date.today.last_year
      @event.end_date = Date.today.last_year + 5.days
      @event.save!

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('You cannot RSVP for past events')
    end

    it 'expired invitations' do
      @invitation.expires = Date.today.last_year
      @invitation.save

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

      expect(page).to have_text('Error finding event membership')
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
        allow(EmailOrganizerNoticeJob).to receive(:perform_later)
        visit rsvp_no_path(@invitation.code)
        fill_in 'rsvp_organizer_message', with: "Sorry I can't make it!"
        click_button 'Decline Attendance'
      end

      it 'queues background task for emailing organizer with message' do
        @args['organizer_message'] = "Sorry I can't make it!"
        expect(EmailOrganizerNoticeJob).to have_received(:perform_later)
          .with(@invitation.membership.id, @args)
      end

      it 'says thanks' do
        expect(page).to have_text('Thank you')
      end

      it 'declines membership' do
        expect(Membership.find(@membership.id).attendance).to eq('Declined')
      end

      it 'destroys invitation' do
        expect(Invitation.where(id: @invitation.id)).to be_empty
      end

      it 'forwards to feedback form, with flash message' do
        expect(current_path).to eq(rsvp_feedback_path(@membership.id))
        expect(page.body).to have_css('div.alert.alert-success.flash', text:
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

    it 'displays invitation expiry date' do
      expect(page).to have_text(@invitation.expire_date)
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
        allow(EmailOrganizerNoticeJob).to receive(:perform_later)
        visit rsvp_maybe_path(@invitation.code)
        fill_in "rsvp_organizer_message", with: 'I might be there'
        click_button "Send Reply"
      end

      it 'includes message in the organizer notice' do
        @args['organizer_message'] = 'I might be there'
        expect(EmailOrganizerNoticeJob).to have_received(:perform_later)
          .with(@invitation.membership.id, @args)
      end

      it 'changes membership attendance to Undecided' do
        expect(Membership.find(@membership.id).attendance).to eq('Undecided')
      end

      it 'forwards to feedback form, with flash message' do
        expect(current_path).to eq(rsvp_feedback_path(@membership.id))
        expect(page.body).to have_css('div.alert.alert-success.flash', text:
          'Your attendance status was successfully updated. Thanks for your
          reply!'.squish)
      end

      it 'updates legacy database' do
        allow(SyncMembershipJob).to receive(:perform_later)
        reset_database

        visit rsvp_maybe_path(@invitation.code)
        click_button 'Send Reply'

        expect(SyncMembershipJob).to have_received(:perform_later)
          .with(@membership.id)
      end
    end
  end

  context 'User says Yes' do
    before do
      reset_database
      @rsvp = RsvpForm.new(@invitation)
      visit rsvp_otp_path(@invitation.code)
      click_link "Yes"
    end

    it 'has arrival and departure date section' do
      expect(page).to have_text(@event.dates(:long))
      expect(page).to have_text(@rsvp.arrival_departure_intro)
    end

    it 'arrival & departure default to event start & end' do
      expect(page).to have_select('rsvp_membership_arrival_date',
        selected: @event.start_date.strftime("%Y-%m-%d"))
      expect(page).to have_select('rsvp_membership_departure_date',
        selected: @event.end_date.strftime("%Y-%m-%d"))
    end

    it 'has guests form' do
      expect(page).to have_text(@rsvp.guests_intro)
      expect(page).to have_css('input#rsvp_membership_has_guest')
      expect(page).to have_css('input#rsvp_membership_guest_disclaimer')
    end

    it 'has special info/food form' do
      expect(page).to have_text(@rsvp.special_intro)
      expect(page).to have_css('textarea#rsvp_membership_special_info')
    end

    it 'has personal profile form' do
      expect(page).to have_text('Personal Information')
      expect(page).to have_field('rsvp_person_firstname')
      expect(page).to have_field('rsvp_person_lastname')
      expect(page).to have_field('rsvp_person_affiliation')
      expect(page).to have_field('rsvp_person_email')
      expect(page).to have_field('rsvp_membership_share_email')
      expect(page).to have_field('rsvp_membership_share_email_hotel')
      expect(page).to have_field('rsvp_person_url')
      expect(page).to have_field('rsvp_person_address1')
      expect(page).to have_field('rsvp_person_city')
      expect(page).to have_field('rsvp_person_region')
      expect(page).to have_field('rsvp_person_country')
      expect(page).to have_field('rsvp_person_biography')
      expect(page).to have_field('rsvp_person_research_areas')
    end

    it 'has privacy notice' do
      expect(page).to have_text(@rsvp.privacy_notice)
    end

    it 'has "message to the organizer" form' do
      organizer_name = @event.organizer.name
      expect(page).to have_text(organizer_name)
      expect(page).to have_field("rsvp_organizer_message")
    end

    it 'persists the organizer message through form validation' do
      fill_in 'rsvp_organizer_message', with: 'Hi Org!'
      fill_in 'rsvp_person_firstname', with: ''

      click_button 'Confirm Attendance'

      expect(page.body).to have_text("firstname can't be blank")
      expect(page).to have_css('textarea#rsvp_organizer_message',
        text: 'Hi Org!')
    end

    it 'persists staff attributes from before RSVP' do
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

    it 'skips the "message to organizer" form if the user is the organizer' do
      @membership.role = 'Contact Organizer'
      @membership.save

      visit rsvp_otp_path(@invitation.code)
      click_link "Yes"
      expect(page).not_to have_field("rsvp_organizer_message")

      @membership.role = 'Participant'
      @membership.save
    end

    context 'after the "Confirm Attendance" button' do
      before do
        @args = { 'attendance_was' => 'Invited',
                  'attendance' => 'Confirmed',
                  'organizer_message' => '' }
        allow(EmailParticipantConfirmationJob).to receive(:perform_later)
        allow(EmailOrganizerNoticeJob).to receive(:perform_later)
        visit rsvp_yes_path(@invitation.code)
        fill_in "rsvp_organizer_message", with: 'Excited to attend!'
        fill_in 'rsvp_person_url', with: 'http://foo.com'
        click_button 'Confirm Attendance'
      end

      it 'saves person data' do
        expect(Person.find(@membership.person_id).url).to eq('http://foo.com')
      end

      it 'changes membership attendance to confirmed' do
        expect(Membership.find(@membership.id).attendance).to eq('Confirmed')
      end

      it 'includes message in the organizer notice' do
        @args['organizer_message'] = 'Excited to attend!'
        expect(EmailOrganizerNoticeJob).to have_received(:perform_later)
          .with(@invitation.membership.id, @args)
      end

      it 'sends confirmation email to participant via background job' do
        expect(EmailParticipantConfirmationJob)
          .to have_received(:perform_later).with(@membership.id)
      end

      it 'destroys invitation' do
        expect(Invitation.where(id: @invitation.id)).to be_empty
      end

      it 'forwards to feedback form, with flash message' do
        expect(current_path).to eq(rsvp_feedback_path(@membership.id))
        expect(page.body).to have_css('div.alert.alert-success.flash', text:
          'Your attendance status was successfully updated. Thanks for your
          reply!'.squish)
      end

      it 'updates legacy database' do
        allow(SyncMembershipJob).to receive(:perform_later)
        reset_database

        visit rsvp_yes_path(@invitation.code)
        click_button 'Confirm Attendance'

        expect(SyncMembershipJob).to have_received(:perform_later)
          .with(@membership.id)
      end
    end
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
