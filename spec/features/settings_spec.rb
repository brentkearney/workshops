# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Settings page', type: :feature do

  context 'As an external user' do
    it 'disallows users who are not logged in' do
      visit settings_path

      expect(page.body).to have_text('You need to sign in or sign up')
      expect(current_path).to eq(user_session_path)
    end
  end

  context 'As a member user' do
    before do
      @person = create(:person)
      @user = create(:user, person: @person, role: 'member')
      login_as @user, scope: :user
    end

    before :each do
      visit settings_path
    end

    it 'allows logged-in users' do
      expect(current_path).to eq(settings_path)
    end

    it 'default tab is user profile settings' do
      expect(page.body).to have_text(@person.name)
      expect(page.body).to have_text('Gender:')
      expect(page.body).to have_text('Affiliation:')
      expect(page.body).to have_text(@person.affiliation)
      expect(page.body).to have_text('Email:')
      expect(page.body).to have_text(@person.email)
      expect(page.body).to have_link('Edit Profile')
    end

    it 'has no "Add Setting" link for non-admin users' do
      expect(page.body).not_to have_link('Add Setting')
    end
  end

  context 'As an admin user' do
    before do
      @person = create(:person)
      @user = create(:user, person: @person, role: 'admin')
      login_as @user, scope: :user
    end

    it 'has an "Add Setting" link' do
      visit settings_path

      expect(page.body).to have_link('Add Setting')
    end

    it '"Add Setting" link opens new_setting_path' do
      visit settings_path
      click_link 'Add Setting'

      expect(current_path).to eq(new_setting_path)
    end

    it '"Add Setting" section has a form that adds settings' do
      visit new_setting_path

      fill_in 'Setting Name:', with: 'Testing'
      fill_in 'Setting Value:', with: 'This is a test value.'
      click_button 'Add Setting'

      expect(page.body).to have_text('Added "Testing" setting!')
    end

    it 'has a link for each Setting name'
  end

end
