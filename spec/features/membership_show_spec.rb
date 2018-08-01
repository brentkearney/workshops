# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Membership#show', type: :feature do
  before do
    Event.destroy_all
    @event = create(:event_with_members)
    @organizer = @event.memberships.where("role='Contact Organizer'").first
    @participant = @event.memberships.where("role='Participant'").first
    @participant.own_accommodation = false
    @participant.person.phd_year = '1992'
    @participant.person.emergency_contact = 'Mom'
    @participant.person.emergency_phone = '1234'
    @participant.save
    @other_membership = create(:membership, person: @participant.person)
    @unconfirmed_membership = create(:membership, attendance: 'Not Yet Invited',
                                     person: @participant.person)

    @participant_user = create(:user, email: @participant.person.email,
                                      person: @participant.person)
    @non_member_user = create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  after do
    Event.destroy_all
  end

  def shows_basic_info(member)
    expect(page.body).to have_css('h2#profile-name', text: member.person.name)
    expect(page.body).to have_css('div#profile-affil',
                                  text: member.person.affil_with_title)
    expect(page.body).to have_css('div#profile-url', text: member.person.uri)
    expect(page.body).to have_css('div#profile-bio',
                                  text: member.person.biography)
    expect(page.body).to have_css('div#profile-research',
                                  text: member.person.research_areas)
  end

  def hides_email(member)
    expect(page.body).not_to have_text(member.person.email)
  end

  def shows_shared_email(member)
    member.share_email = true
    member.save
    visit event_membership_path(@event, member)

    expect(page.body).to have_text(member.person.email)
  end

  def hides_unshared_email(member)
    member.share_email = false
    member.save
    visit event_membership_path(@event, member)

    expect(page.body).not_to have_text(member.person.email)
  end

  def shows_unshared_email(member)
    member.share_email = false
    member.save

    visit event_membership_path(@event, member)
    expect(page.body).to have_text(member.person.email)
  end

  def shows_personal_info(member)
    expect(page.body).to have_css('div#profile-address')
    expect(page.body).to have_text(member.person.address1)
    expect(page.body).to have_text(member.person.city)
    expect(page.body).to have_text(member.person.postal_code)
    expect(page.body).to have_css('div#profile-phd_year')
    expect(page.body).to have_css('div#profile-emergency_contact')
    expect(page.body).to have_css('div#profile-academic-status',
                                  text: member.person.academic_status)
  end

  def hides_personal_info(member)
    expect(page.body).not_to have_css('div#profile-address')
    expect(page.body).not_to have_text(member.person.address1)
    expect(page.body).not_to have_text(member.person.city)
    expect(page.body).not_to have_text(member.person.postal_code)
    expect(page.body).not_to have_css('div#profile-academic-status')
  end

  def shows_details(member)
    expect(page.body).to have_css('div#profile-phone',
                                      text: member.person.phone)
    expect(page.body).to have_css('div.updated-by',
                                  text: member.person.updated_by)
    expect(page.body).to have_css('div.membership-details')
    expect(page.body).to have_text(member.arrives)
    expect(page.body).to have_text(member.departs)
    expect(page.body).to have_text(member.rsvp_date)
  end

  def shows_organizer_notes(member)
    expect(page.body).to have_text(member.org_notes)
  end

  def hides_organizer_notes(member)
    expect(page.body).not_to have_text(member.org_notes)
  end

  def does_not_show_details(member)
    expect(page.body).not_to have_css('div#profile-academic-status',
                                      text: member.person.academic_status)
    expect(page.body).not_to have_css('div.updated-by',
                                      text: member.person.updated_by)
    expect(page.body).not_to have_css('div.membership-details')
    expect(page.body).not_to have_text(member.arrives)
    expect(page.body).not_to have_text(member.departs)
    expect(page.body).not_to have_text(member.rsvp_date)
    expect(page.body).not_to have_text(member.org_notes)
  end

  def shows_hotel_billing(member)
    expect(page.body).to have_css('div.hotel-billing')
    expect(page.body).to have_css('div#profile-reviewed')
    expect(page.body).to have_css('div#profile-billing',
                                  text: member.billing)
    expect(page.body).to have_css('div#profile-gender',
                                  text: member.person.gender)
    expect(page.body).to have_css('div#profile-room',
                                  text: member.room)
    expect(page.body).to have_css('div#profile-has-guest')
    expect(page.body).to have_css('div#profile-special-info',
                                  text: member.special_info)
    expect(page.body).to have_css('div#profile-staff-notes',
                                  text: member.staff_notes)
  end

  def does_not_show_hotel_billing(member)
    expect(page.body).not_to have_css('div.hotel-billing')
    expect(page.body).not_to have_css('div#profile-reviewed',
                                      text: member.reviewed)
    expect(page.body).not_to have_css('div#profile-billing',
                                      text: member.billing)
    expect(page.body).not_to have_css('div#profile-gender',
                                          text: member.person.gender)
    expect(page.body).not_to have_css('div#profile-room',
                                      text: member.room)
    expect(page.body).not_to have_css('div#profile-stay-id',
                                      text: member.stay_id)
    expect(page.body).not_to have_css('div#profile-has-guest',
                                      text: member.has_guest)
    expect(page.body).not_to have_css('div#profile-special-info',
                                      text: member.special_info)
    expect(page.body).not_to have_css('div#profile-staff-notes',
                                      text: member.staff_notes)
  end

  def denies_access(member)
    visit event_membership_path(@event, member)
    expect(page.body).not_to have_css('div#profile-name',
                                      text: member.person.name)
    expect(page.body).to have_css('div.alert.flash')
  end


  context 'As a not-logged in user' do
    before do
      visit event_membership_path(@event, @organizer)
    end

    it 'denies access' do
      denies_access(@organizer)
    end

    it 'excludes email' do
      hides_email(@organizer)
    end

    it 'excludes personal info' do
      hides_personal_info(@organizer)
    end

    it 'excludes details' do
      does_not_show_details(@organizer)
    end

    it 'excludes hotel & billing' do
      does_not_show_hotel_billing(@organizer)
    end

    it 'excludes edit and delete buttons' do
      expect(page).not_to have_link 'Edit Membership'
      expect(page).not_to have_link 'Delete Membership'
    end

    it 'denies access to non-confirmed members profiles' do
      nonconfirmed = @event.memberships.where("role='Participant'").last

      nonconfirmed.attendance = 'Declined'
      nonconfirmed.save
      denies_access(nonconfirmed)

      nonconfirmed.attendance = 'Invited'
      nonconfirmed.save
      denies_access(nonconfirmed)

      nonconfirmed.attendance = 'Not Yet Invited'
      nonconfirmed.save
      denies_access(nonconfirmed)
    end

    it 'denies access to other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).not_to have_css('div#other-memberships')
      expect(page.body).not_to have_text(@other_membership.event.name)
      denies_access(@participant)
    end

    it 'hides unconfirmed other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).not_to have_text(@unconfirmed_membership.event.name)
    end
  end

  context 'As a logged-in user who is not a member of the event' do
    before do
      login_as @non_member_user, scope: :user
      visit event_membership_path(@event, @organizer)
    end

    it 'shows basic personal info' do
      shows_basic_info(@organizer)
    end

    it 'excludes email' do
      hides_email(@organizer)
    end

    it 'excludes personal info' do
      hides_personal_info(@organizer)
    end

    it 'excludes details' do
      does_not_show_details(@organizer)
    end

    it 'excludes hotel & billing' do
      does_not_show_hotel_billing(@organizer)
    end

    it 'excludes edit and delete buttons' do
      expect(page).not_to have_link 'Edit Membership'
      expect(page).not_to have_link 'Delete Membership'
    end

    it 'denies access to non-confirmed members profiles' do
      nonconfirmed = @event.memberships.where("role='Participant'").last

      nonconfirmed.attendance = 'Declined'
      nonconfirmed.save
      denies_access(nonconfirmed)

      nonconfirmed.attendance = 'Invited'
      nonconfirmed.save
      denies_access(nonconfirmed)

      nonconfirmed.attendance = 'Not Yet Invited'
      nonconfirmed.save
      denies_access(nonconfirmed)
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'hides unconfirmed other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).not_to have_text(@unconfirmed_membership.event.name)
    end
  end

  context "As a member of the event viewing someone else's profile" do
    before do
      login_as @participant_user, scope: :user
      @other_membership.person = @organizer.person
      @other_membership.save
      visit event_membership_path(@event, @organizer)
    end

    after do
      @other_membership.person = @participant.person
      @other_membership.save
    end

    it 'shows basic personal info' do
      shows_basic_info(@organizer)
    end

    it 'shows email if shared' do
      shows_shared_email(@organizer)
    end

    it 'hides email if not shared' do
      hides_unshared_email(@organizer)
    end

    it 'excludes personal info' do
      hides_personal_info(@organizer)
    end

    it 'excludes details' do
      does_not_show_details(@organizer)
    end

    it 'excludes hotel & billing' do
      does_not_show_hotel_billing(@organizer)
    end

    it 'excludes edit and delete buttons' do
      expect(page).not_to have_link 'Edit Membership'
      expect(page).not_to have_link 'Delete Membership'
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @organizer)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'hides unconfirmed other memberships' do
      visit event_membership_path(@event, @organizer)
      expect(page.body).not_to have_text(@unconfirmed_membership.event.name)
    end
  end

  context 'As a member of the event viewing their own profile' do
    before do
      login_as @participant_user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows basic personal info' do
      shows_basic_info(@participant)
    end

    it 'shows email if shared' do
      shows_shared_email(@participant)
    end

    it 'hides email if not shared' do
      hides_unshared_email(@participant)
    end

    it 'shows personal info' do
      shows_personal_info(@participant)
    end

    it 'shows details' do
      shows_details(@participant)
    end

    it 'excludes organizer notes' do
      hides_organizer_notes(@participant)
    end

    it 'excludes hotel & billing' do
      does_not_show_hotel_billing(@organizer)
    end

    it 'includes edit button' do
      expect(page).to have_link 'Edit Membership'
    end

    it 'excludes delete button' do
      expect(page).not_to have_link 'Delete Membership'
    end

    it 'hides academic status if empty' do
      @participant.person.academic_status = ''
      @participant.save

      visit event_membership_path(@event, @participant)

      expect(page).not_to have_css('div#profile-academic-status')
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'does not hide unconfirmed other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_text(@unconfirmed_membership.event.name)
    end
  end

  context 'As an organizer of the event' do
    before do
      organizer_user = create(:user, email: @organizer.person.email,
                                      person: @organizer.person)
      login_as organizer_user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows basic personal info' do
      shows_basic_info(@participant)
    end

    it 'shows email if shared' do
      shows_shared_email(@participant)
    end

    it 'shows email if not shared' do
      shows_unshared_email(@participant)
    end

    it 'hides personal info' do
      hides_personal_info(@participant)
    end

    it 'shows details' do
      shows_details(@participant)
    end

    it 'shows organizer notes' do
      shows_organizer_notes(@participant)
    end

    it 'excludes hotel & billing' do
      does_not_show_hotel_billing(@participant)
    end

    it 'includes edit button' do
      expect(page).to have_link 'Edit Membership'
    end

    it 'excludes delete button' do
      expect(page).not_to have_link 'Delete Membership'
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'hides unconfirmed other memberships' do
      visit event_membership_path(@event, @organizer)
      expect(page.body).not_to have_text(@unconfirmed_membership.event.name)
    end

    it 'does not hide unconfirmed other memberships of same organizer' do
      m = create(:membership, event: @unconfirmed_membership.event,
                              role: 'Organizer', person: @organizer.person)
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_text(@unconfirmed_membership.event.name)
      m.destroy!
    end
  end

  context 'As a staff user at a different location' do
    before do
      @non_member_user.role = :staff
      @non_member_user.location = 'elsewhere'
      @non_member_user.save
      login_as @non_member_user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows basic personal info' do
      shows_basic_info(@participant)
    end

    it 'excludes email' do
      hides_email(@participant)
    end

    it 'excludes personal info' do
      hides_personal_info(@participant)
    end

    it 'excludes details' do
      does_not_show_details(@participant)
    end

    it 'excludes hotel & billing' do
      does_not_show_hotel_billing(@participant)
    end

    it 'excludes edit and delete buttons' do
      expect(page).not_to have_link 'Edit Membership'
      expect(page).not_to have_link 'Delete Membership'
    end

    it 'denies access to non-confirmed members profiles' do
      nonconfirmed = @event.memberships.where("role='Participant'").last

      nonconfirmed.attendance = 'Declined'
      nonconfirmed.save
      denies_access(nonconfirmed)

      nonconfirmed.attendance = 'Invited'
      nonconfirmed.save
      denies_access(nonconfirmed)

      nonconfirmed.attendance = 'Not Yet Invited'
      nonconfirmed.save
      denies_access(nonconfirmed)
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'hides unconfirmed other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).not_to have_text(@unconfirmed_membership.event.name)
    end
  end

  context 'As a staff user at the same location' do
    before do
      @non_member_user.role = :staff
      @non_member_user.location = @event.location
      @non_member_user.save
      login_as @non_member_user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows basic personal info' do
      shows_basic_info(@participant)
    end

    it 'shows email if shared' do
      shows_shared_email(@participant)
    end

    it 'shows email if not shared' do
      shows_unshared_email(@participant)
    end

    it 'shows personal info' do
      shows_personal_info(@participant)
    end

    it 'shows details' do
      shows_details(@participant)
    end

    it 'hides organizer notes' do
      hides_organizer_notes(@participant)
    end

    it 'shows hotel & billing' do
      shows_hotel_billing(@participant)
    end

    it 'hides room and shows own accommodation if true' do
      @participant.own_accommodation = true
      @participant.save

      visit event_membership_path(@event, @participant)

      expect(page.body).not_to have_css('div#profile-room',
                                        text: @participant.room)
      expect(page.body).to have_css('div#profile-ownaccommodation',
                                    text: 'Own Accommodation')

      @participant.own_accommodation = false
      @participant.save
    end

    it 'includes edit and delete buttons' do
      expect(page).to have_link 'Edit Membership'
      expect(page).to have_link 'Delete Membership'
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'does not hide unconfirmed other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_text(@unconfirmed_membership.event.name)
    end
  end

  context 'As an admin user' do
    before do
      @non_member_user.role = :admin
      @non_member_user.save
      login_as @non_member_user, scope: :user
      visit event_membership_path(@event, @participant)
    end

    it 'shows basic personal info' do
      shows_basic_info(@participant)
    end

    it 'shows email if shared' do
      shows_shared_email(@participant)
    end

    it 'shows email if not shared' do
      shows_unshared_email(@participant)
    end

    it 'shows personal info' do
      shows_personal_info(@participant)
    end

    it 'shows details' do
      shows_details(@participant)
    end

    it 'shows organizer notes' do
      shows_organizer_notes(@participant)
    end

    it 'shows hotel & billing' do
      shows_hotel_billing(@participant)
    end

    it 'hides room and shows own accommodation if true' do
      @participant.own_accommodation = true
      @participant.save

      visit event_membership_path(@event, @participant)

      expect(page.body).not_to have_css('div#profile-room',
                                        text: @participant.room)
      expect(page.body).to have_css('div#profile-ownaccommodation',
                                    text: 'Own Accommodation')

      @participant.own_accommodation = false
      @participant.save
    end

    it 'includes edit and delete buttons' do
      expect(page).to have_link 'Edit Membership'
      expect(page).to have_link 'Delete Membership'
    end

    it 'shows other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_css('div#other-memberships')
      expect(page.body).to have_text(@other_membership.event.name)
    end

    it 'does not hide unconfirmed other memberships' do
      visit event_membership_path(@event, @participant)
      expect(page.body).to have_text(@unconfirmed_membership.event.name)
    end
  end
end
