# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Settings page', type: :feature do
  before do
    load "#{Rails.root}/config/initializers/settings.rb"
    expect(Setting.get_all).not_to be_empty
  end

  context 'As an external user' do
    it 'disallows users who are not logged in' do
      visit settings_path

      expect(page.body).to have_text('You need to sign in or sign up')
      expect(current_path).to eq(user_session_path)
    end
  end

  context 'As a member user' do
    it 'denies access' do
      person = create(:person)
      user = create(:user, person: person, role: 'member')
      login_as user, scope: :user

      visit settings_path

      expect(page.body).to have_text('Access denied.')
      expect(current_path).to eq(my_events_path)
    end
  end

  context 'As an admin user' do
    before do
      @person = create(:person)
      @user = create(:user, person: @person, role: 'admin')
      login_as @user, scope: :user
    end

    it 'has tabs for each Setting section' do
      visit settings_path

      Setting.get_all.keys.each do |tab|
        expect(page).to have_link(tab)
      end
    end

    it 'it shows the fields of the Site settings' do
      visit edit_setting_path('Site')

      Setting.Site.keys.each do |field|
        expect(page).to have_field("setting[Site][#{field}]")
      end
    end

    it 'the Locations tab has a sub-tab for each location' do
      visit edit_setting_path('Locations')

      Setting.Locations.keys.each do |tab|
        expect(page).to have_link(tab)
      end
    end

    it 'the "Location code" field updates the key representing that location' do
      visit edit_setting_path('Locations')

      fill_in "setting[Locations][EO][new_key]", with: 'TEST'
      click_button 'Update EO Settings'

      expect(page).to have_text('Setting has been updated')
      expect(Setting.find_by_var('Locations').value.keys.first).to eq('TEST')
    end

    it 'has a +/- Locations tab to add new locations' do
      visit edit_setting_path('Locations')

      click_link '+/- Location'
      fill_in 'setting[Locations][new_location]', with: 'TEST2'
      click_button 'Create New Location'

      expect(page).to have_text('Setting has been updated')
      expect(page).to have_link('TEST2')
      expect(Setting.find_by_var('Locations').value.keys).to include('TEST2')
    end

  end

end
