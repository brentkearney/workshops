# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Visitor SignIn', :type => :feature do
  before do
    @person = FactoryGirl.create(:person)
    @password = Faker::Internet.password(12)
    @user = FactoryGirl.create(:user, password: @password, password_confirmation: @password, person: @person)
    @user.confirmed_at = Time.now
    @user.save
    expect(@user).to be_valid
    expect(@user.person).to eq(@person)

    @event = FactoryGirl.create(:event)
    @membership = FactoryGirl.create(:membership, event: @event, person: @person, attendance: 'Invited')
  end

  before :each do
    visit sign_in_path
  end

  def fill_in_form
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: @password
    click_button 'Sign in'
  end

  it 'Allows a user to login with email and password' do
    fill_in_form
    expect(page.body).to have_text('Signed in successfully')
  end

  it "The character case of the email does not matter" do
    fill_in 'Email', with: @user.email.upcase
    fill_in 'Password', with: @password

    click_button 'Sign in'

    expect(page.body).to have_text('Signed in successfully')
  end

  it 'Denies a user to login with incorrect credentials' do
    fill_in 'Email', with: 'nonsense@foo.bar'
    fill_in 'Password', with: @password
    click_button 'Sign in'
    expect(page.body).not_to have_text('Signed in successfully')
    expect(page.body).to have_text('Invalid email or password')

    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'Rubbish'
    click_button 'Sign in'
    expect(page.body).not_to have_text('Signed in successfully')
    expect(page.body).to have_text('Invalid email or password')

    fill_in 'Email', with: 'nonsense@foo.bar'
    fill_in 'Password', with: 'Rubbish'
    click_button 'Sign in'
    expect(page.body).not_to have_text('Signed in successfully')
    expect(page.body).to have_text('Invalid email or password')
  end

  it 'Forwards user to "My Events" page after signin' do
    fill_in_form
    expect(page.body).to have_text('Signed in successfully')
    expect(current_path).to eq(my_events_path)
  end

  it 'Denies logins to non-admin users who have no memberships' do
    @user.member!
    @person.memberships.destroy_all
    expect(@user.person.memberships).to be_empty

    fill_in_form
    expect(page.body).not_to have_text('Signed in successfully')
    expect(current_path).to eq(sign_in_path)
  end

  it 'Denies participants with memberships but who have not been invited' do
    @user.member!
    @user.person.memberships.destroy_all
    expect(@user.person.memberships).to be_empty
    m = FactoryGirl.create(:membership, person: @user.person, attendance: 'Not Yet Invited', role: 'Participant')
    visit sign_in_path
    fill_in_form
    expect(page.body).not_to have_text('Signed in successfully')
    expect(current_path).to eq(sign_in_path)
  end

  it 'Allows organizers with memberships and declined attendance' do
    @user.member!
    @user.person.memberships.destroy_all
    event = create(:event, start_date: Date.today.next_week(:sunday),
                   end_date: Date.today.next_week(:sunday) + 5.days )
    membership = create(:membership, event: event, person: @user.person, attendance: 'Declined', role: 'Organizer')

    visit sign_in_path
    fill_in_form

    expect(page.body).to have_text(membership.event.name)
    expect(current_path).to eq(welcome_path)
  end

  it 'Forwards users with no current events to My Events' do
    @user.member!
    @user.person.memberships.destroy_all
    event = create(:event, start_date: Date.today.prev_year.prev_week(:sunday),
                  end_date: Date.today.prev_year.prev_week(:sunday) + 5.days)
    create(:membership, person: @user.person, event: event, attendance: 'Confirmed')

    visit sign_in_path
    fill_in_form

    expect(page.body).to have_text('Signed in successfully')
    expect(current_path).to eq(my_events_path)
  end
end