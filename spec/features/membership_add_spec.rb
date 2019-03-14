# ./spec/features/membership_add_spec.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Membership#add', type: :feature do
  before do
    @event = create(:event_with_members)
    @event.start_date = (Date.current + 1.month).beginning_of_week(:sunday)
    @event.end_date = @event.start_date + 5.days
    @event.save
    organizer = @event.memberships.where("role='Contact Organizer'").first
    @org_user = create(:user, email: organizer.person.email,
                             person: organizer.person)
    @participant = @event.memberships.where("role='Participant'").first
  end

  describe 'Visibility of Add Members button, access to page' do
    before do
      @user = create(:user)
    end

    it 'hides from public users' do
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(user_session_path)
      expect(page).to have_text('You need to sign in')
    end

    it 'hides from non-member users' do
      login_as @user, scope: :user
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(my_events_path)
      expect(page).to have_text('Access denied')

      logout(@user)
    end

    it 'hides from member users' do
      @user.email = @participant.person.email
      @user.person = @participant.person
      @user.save

      login_as @user, scope: :user
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(my_events_path)
      expect(page).to have_text('Access denied')

      logout(@user)
    end

    it 'shows to organizer users' do
      login_as @org_user, scope: :user
      visit event_memberships_path(@event)
      expect(page).to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(add_event_memberships_path(@event))
      logout(@org_user)
    end

    it 'shows to staff users' do
      @user.staff!
      login_as @user
      visit event_memberships_path(@event)
      expect(page).to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(add_event_memberships_path(@event))
      logout(@user)
    end

    it 'shows to admin users' do
      @user.admin!
      login_as @user
      visit event_memberships_path(@event)
      expect(page).to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(add_event_memberships_path(@event))
      logout(@user)
    end

    it 'hides if the event is in the past' do
      @event.start_date = (Date.current - 1.month).beginning_of_week(:sunday)
      @event.end_date = @event.start_date + 5.days
      @event.save

      login_as @org_user, scope: :user
      visit event_memberships_path(@event)
      expect(page).not_to have_link("Add Members")

      visit add_event_memberships_path(@event)
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text('Access denied')

      @event.start_date = (Date.current + 1.month).beginning_of_week(:sunday)
      @event.end_date = @event.start_date + 5.days
      @event.save
      logout(@org_user)
    end
  end

  describe 'Add Members form' do
    before do
      login_as @org_user
      visit add_event_memberships_path(@event)
      @person = @participant.person
      @participant.destroy
      @lc = FakeLegacyConnector.new
      allow(LegacyConnector).to receive(:new).and_return(@lc)
    end

    it 'has a title, a text area, a role select, and a submit button' do
      expect(page).to have_css('h1', text: "Add Members to #{@event.code}")
      expect(page).to have_field('add_members_form[add_members]')
      expect(page).to have_field('add_members_form[role]')
      expect(page).to have_button('Add These Members')
    end

    it 'adds existing local records based on email match' do
      fill_in 'add_members_form[add_members]', with: @person.email
      click_button 'Add These Members'

      expect(page).to have_text('New members added')
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text(@person.lastname)

      #@person.memberships.last.destroy
    end

    it 'imports remote records based on email match' do
      email = 'test@email.com'
      person = Person.find_by_email(email)
      person.destroy unless person.nil?

      np = build(:person, email: email)
      allow(@lc).to receive(:search_person).with(email).and_return(np.attributes)

      fill_in 'add_members_form[add_members]', with: email
      click_button 'Add These Members'

      expect(@lc).to have_received(:search_person)
      new_person = Person.find_by_email(email)
      expect(new_person).not_to be_nil
      expect(page).to have_text('New members added')
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text(new_person.lastname)
    end

    it 'if email does not match, and data is missing, presents new form' do
      email = 'test2@email2.com'
      person = Person.find_by_email(email)
      person.destroy unless person.nil?

      fill_in 'add_members_form[add_members]', with: email
      click_button 'Add These Members'

      expect(current_path).to eq(add_event_memberships_path(@event))
      email_field = 'add_members_form[new_people][][email]'
      expect(page.find_field(email_field).value).to eq(email)
      expect(page).to have_field('add_members_form[new_people][][lastname]')
      expect(page).to have_field('add_members_form[new_people][][firstname]')
      expect(page).to have_field('add_members_form[new_people][][affiliation]')
    end

    it 'if email does not match, and data is complete, adds new person' do
      email = 'test@email.com'
      person = Person.find_by_email(email)
      person.destroy unless person.nil?

      data = 'test@email.com, Pow, Zap, Zingzang Electric Co.'
      fill_in 'add_members_form[add_members]', with: data
      click_button 'Add These Members'

      new_person = Person.find_by_email(email)
      expect(new_person).not_to be_nil
      expect(page).to have_text('New members added')
      expect(current_path).to eq(event_memberships_path(@event))
      expect(page).to have_text(new_person.lastname)
    end
  end

  describe 'New people form' do
    before do
      @lc = FakeLegacyConnector.new
      allow(LegacyConnector).to receive(:new).and_return(@lc)

      login_as @org_user
      visit add_event_memberships_path(@event)
    end

    it 'validates emails' do
      sample_data = "foo@bar.com, ,Foo\nbademail, Kerluke, Ron, Bad Email Co\n"
      fill_in 'add_members_form[add_members]', with: sample_data
      click_button 'Add These Members'

      element = find('li', text: 'Lastname is required, Affiliation is required.')
      expect(element).not_to be_blank
      element = find('li', text: 'E-mail is invalid.')
      expect(element).not_to be_blank

      email_field = 'add_members_form[new_people][][email]'
      email_fields = page.all(:fillable_field, email_field)
      expect(email_fields.first.value).to eq('foo@bar.com')
      expect(email_fields.last.value).to eq('bademail')
    end

    it 'validates incomplete data' do
      email = 'foo@bar.com'
      person = Person.find_by_email(email)
      person.destroy unless person.nil?

      sample_data = "#{email}, Bar, Foo\n"
      fill_in 'add_members_form[add_members]', with: sample_data
      click_button 'Add These Members'

      fill_in 'add_members_form[new_people][][firstname]', with: ''
      fill_in 'add_members_form[new_people][][affiliation]', with: 'Foofoo'
      click_button 'Add These Members'

      element = find('li', text: 'Firstname is required.')
      expect(element).not_to be_blank

      fill_in 'add_members_form[new_people][][firstname]', with: 'Foo'
      click_button 'Add These Members'

      expect(page).to have_text('New members added')
      new_person = Person.find_by_email(email)
      expect(new_person).not_to be_nil
    end
  end
end
