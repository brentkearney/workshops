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

  context 'As a staff user' do
    it 'allows access to the Rooms section'
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

    context 'Site tab' do
      it 'shows the fields of the Site settings' do
        visit edit_setting_path('Site')

        Setting.Site.keys.each do |field|
          expect(page).to have_field("setting[Site][#{field}]")
        end
      end

      it 'has the minimum necessary fields for the app to function' do
        required_fields = %w(title footer events_url legacy_person legacy_api
            application_email webmaster_email sysadmin_email)

        visit edit_setting_path('Site')

        required_fields.each do |field|
          expect(page).to have_field("setting[Site][#{field}]")
        end
      end

      it 'updates data' do
        visit edit_setting_path('Site')
        fill_in 'setting[Site][title]', with: 'Test Title'
        click_button 'Update Settings'

        expect(page).to have_text('Setting has been updated')
        setting = Setting.find_by_var('Site')
        expect(setting.value['title']).to eq('Test Title')
      end

      it 'accepts array values' do
        visit edit_setting_path('Site')

        fill_in 'setting[Site][new_field]', with: 'Breakfast'
        fill_in 'setting[Site][new_value]', with: '[Lunch, Dinner, Desert]'
        click_button 'Update Settings'

        expect(page).to have_text('Setting has been updated')
        setting = Setting.find_by_var('Site')
        expect(setting.value['Breakfast'].class).to eq(Array)
      end

      it 'has a way to delete fields'
    end

    context 'Emails tab' do
      it 'has a sub-tab for each location'
    end

    context 'Locations tab' do
      it 'has a sub-tab for each location' do
        visit edit_setting_path('Locations')

        Setting.Locations.keys.each do |tab|
          expect(page).to have_link(tab)
        end
      end

      it 'has a form field for each key:value pair of the location'
      it 'updates the data in the given field'
      it 'has an "Add New Field" form that adds new fields'


      it '"Location code" field updates the key representing that location' do
        visit edit_setting_path('Locations')

        fill_in "setting[Locations][EO][new_key]", with: 'TEST'
        click_button 'Update EO Settings'

        expect(page).to have_text('Setting has been updated')
        expect(Setting.find_by_var('Locations').value.keys.first).to eq('TEST')
      end

      it 'has a "+/- Location" tab to add new locations' do
        visit edit_setting_path('Locations')

        click_link '+/- Location'
        fill_in 'setting[Locations][new_location]', with: 'TEST2'
        click_button 'Create New Location'

        expect(page).to have_text('Setting has been updated')
        expect(page).to have_link('TEST2')
        expect(Setting.find_by_var('Locations').value.keys).to include('TEST2')
      end

      it 'updates the location keys of the other Setting sections as well' do
        visit edit_setting_path('Locations')

        click_link '+/- Location'
        fill_in 'setting[Locations][new_location]', with: 'TEST3'
        click_button 'Create New Location'

        (Setting.get_all.keys - ['Site', 'Locations']).each do |section|
          expect(Setting.send(section).keys).to include(:TEST3)
        end
      end
    end

    context 'Rooms tab' do
      it 'has sub-tabs for each location'
      it 'has a form for adding new rooms'
    end

    context '+/- Setting tab' do
      it 'has a form for adding new setting sections'
      it 'a new tab appears for the new setting section'
      it 'asks if the new section is location-dependent'
      it 'if location dependent, populates new section with location tabs'
      it 'the Add New field sub-tab is pre-selected in the new section'
      it 'has a form for deleting existing setting sections'
    end
  end

end
