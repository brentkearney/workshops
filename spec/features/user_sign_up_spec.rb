# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Visitor Signup', :type => :feature do
  before :each do
    @event = FactoryGirl.create(:event)
    @person = FactoryGirl.create(:person)
    @membership = FactoryGirl.create(:membership, person: @person, event: @event)
    @password = Faker::Internet.password(12)

    visit new_user_registration_path
  end

  it 'Is denied if visitor email is not associated with a Person record' do
    fill_in 'user_email', with: 'blaaarg@bleh.com'
    fill_in 'user_password', with: @password
    fill_in 'user_password_confirmation', :with => @password
    click_button 'Sign up'
    expect(page).to have_text('We have no record of that email address.')
  end

  it 'Is denied if visitor enters invalid email address' do
    fill_in 'user_email', with: 'foo'
    click_button 'Sign up'
    expect(page).to have_text('You must enter a valid e-mail address.')
  end

  context 'If the email address is associated with a Person record' do
    context 'and that Person record is an active member of an Event' do
      def enter_credentials
        fill_in 'user_email', with: @person.email
        fill_in 'user_password', with: @password
        fill_in 'user_password_confirmation', :with => @password
        click_button 'Sign up'
      end

      it 'allows visitor to signup' do
        enter_credentials
        expect(page).to have_text('Account successfully created, pending confirmation')
      end

      it 'character case in the email address is irrelevant' do
        fill_in 'user_email', with: @person.email.upcase
        fill_in 'user_password', with: @password
        fill_in 'user_password_confirmation', :with => @password

        click_button 'Sign up'

        expect(page).to have_text('Account successfully created, pending confirmation')
      end

      it 'and it sends a confirmation email' do
        enter_credentials
        user = User.find_by_email(@person.email)

        expect(user.confirmation_token).not_to be_nil
        expect(user.confirmation_sent_at).not_to be_nil
      end

      it 'and it redirects to a post-signup landing page' do
        enter_credentials

        expect(current_path).to eq(confirmation_sent_path)
        expect(page.body).to have_text('To verify that it is really you')
      end
    end

    context 'and that Person record is not an active member of the Event' do

      it 'denies "Declined" participants to signup' do
        @membership.attendance = 'Declined'
        @membership.save!
        fill_in 'user_email', with: @person.email
        fill_in 'user_password', with: @password
        fill_in 'user_password_confirmation', :with => @password
        click_button 'Sign up'
        expect(page).to have_text('We have no records of pending event invitations')
      end

      it 'denies "Not Yet Invited" participants to signup' do
        @membership.attendance = 'Not Yet Invited'
        @membership.save!
        fill_in 'user_email', with: @person.email
        fill_in 'user_password', with: @password
        fill_in 'user_password_confirmation', :with => @password
        click_button 'Sign up'
        expect(page).to have_text('We have no records of pending event invitations')
      end
    end
  end

end
