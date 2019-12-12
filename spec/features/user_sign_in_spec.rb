# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'SignIn', type: :feature do
  before do
    @password = Faker::Internet.password(12)
    @user = create(:user, password: @password, password_confirmation: @password)
    @person = @user.person
    @membership = create(:membership, person: @person, attendance: 'Confirmed')
    @event = @membership.event
  end

  before :each do
    logout(@user)
    visit sign_in_path
  end

  def fill_in_form
    fill_in 'login-email', with: @user.email
    fill_in 'login-password', with: @password
    click_button 'Sign-in'
  end

  it 'Allows a user to login with email and password' do
    fill_in_form

    expect(page.body).to have_text('Signed in successfully')
  end

  it 'The character case of the email does not matter' do
    fill_in 'login-email', with: @user.email.upcase
    fill_in 'login-password', with: @password

    click_button 'Sign-in'

    expect(page.body).to have_text('Signed in successfully')
  end

  it 'Denies a user with incorrect credentials' do
    fill_in 'login-email', with: 'nonsense@foo.bar'
    fill_in 'login-password', with: @password
    click_button 'Sign-in'
    expect(page.body).not_to have_text('Signed in successfully')
    expect(page.body).to have_text('Invalid Email or password')

    fill_in 'login-email', with: @user.email
    fill_in 'login-password', with: 'Rubbish'
    click_button 'Sign-in'
    expect(page.body).not_to have_text('Signed in successfully')
    expect(page.body).to have_text('Invalid Email or password')

    fill_in 'login-email', with: 'nonsense@foo.bar'
    fill_in 'login-password', with: 'Rubbish'
    click_button 'Sign-in'
    expect(page.body).not_to have_text('Signed in successfully')
    expect(page.body).to have_text('Invalid Email or password')
  end

  it 'Denies logins to non-admin users who have no memberships' do
    @user.member!
    @person.memberships.destroy_all

    fill_in_form
    expect(page.body).not_to have_text('Signed in successfully')
    expect(current_path).to eq(sign_in_path)
  end

  it 'Denies participants with memberships but who have not been invited' do
    @user.member!
    @user.person.memberships.destroy_all
    expect(@user.person.memberships).to be_empty
    m = create(:membership, person: @user.person,
      attendance: 'Not Yet Invited', role: 'Participant')
    visit sign_in_path
    fill_in_form
    expect(page.body).not_to have_text('Signed in successfully')
    expect(current_path).to eq(sign_in_path)
  end

  it 'Allows organizers with memberships and declined attendance' do
    @user.member!
    @user.person.memberships.destroy_all
    event = create(:event, future: true)
    membership = create(:membership, event: event,
      person: @user.person, attendance: 'Declined', role: 'Organizer')

    visit sign_in_path
    fill_in_form

    expect(page.body).to have_text(membership.event.name)
    expect(current_path).to eq(home_path)
  end


  it 'Forwards users with current events to home#index page signin' do
    future_event = create(:event, current: true)
    create(:membership, event: future_event, person: @person)
    fill_in_form

    expect(page.body).to have_text('Signed in successfully')
    expect(current_path).to eq(home_path)
  end

  it 'Forwards users with no current events to Future Events' do
    @user.member!
    @user.person.memberships.destroy_all
    event = create(:event, past: true)
    create(:membership, person: @user.person, event: event,
       attendance: 'Confirmed')

    visit sign_in_path
    fill_in_form

    expect(page.body).to have_text('Signed in successfully')
    expect(current_path).to eq(events_future_path)
  end
end
