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

  def find_sub_tabs(section) 
    Setting.find_by_var(section).value.keys.each do |tab|
      tab_pane = 'div.tab-pane#' + tab.to_s
      expect(page.body).to have_css(tab_pane)
    end
  end

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
      @user = create(:user, person: @person, role: 'staff')
      login_as @user, scope: :user
    end

    after do
      logout(@user)
      @person.destroy
    end

    
    it 'does not show a link to Settings in the drop-down user menu' do
      visit root_path
      expect(page).not_to have_css('ul.dropdown-user li a', text: 'Settings')
    end

    it 'denies access' do
      visit settings_path

      expect(page.body).to have_text('Access denied.')
      expect(current_path).to eq(my_events_path)
    end
  end

  context 'As a staff user' do
    before do
      @person = create(:person)
      @user = create(:user, person: @person, role: 'staff')
      login_as @user, scope: :user
    end

    after do
      logout(@user)
      @person.destroy
    end

    it 'does not show a link to Settings in the drop-down user menu' do
      visit root_path
      expect(page).not_to have_css('ul.dropdown-user li a', text: 'Settings')
    end

    it 'denies access' do
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

    after do
      logout(@user)
      @person.destroy
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
          expect(page).to have_field("setting[Site][#{field}]") unless field.empty?
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

        fill_in 'setting[Site][event_types]', with: '[Lunch, Dinner, Desert]'
        click_button 'Update Settings'

        expect(page).to have_text('Setting has been updated')
        setting = Setting.find_by_var('Site')
        expect(setting.value['event_types'].class).to eq(Array)
      end
    end

    context 'Emails tab' do
      before :each do
        visit edit_setting_path('Emails')
      end

      it 'has a sub-tab for each location' do
        find_sub_tabs('Emails')
      end
    end

    context 'Locations tab' do
      before :each do
        visit edit_setting_path('Locations')
      end

      it 'has a sub-tab for each location' do
        find_sub_tabs('Locations')
      end

      it 'has a form field for each field of the location' do 
        Setting.Locations.each do |location, properties|
          properties.each do |field, value|
            expect(page).to have_field("setting[Locations][#{location}][#{field}]")
          end
        end
      end

      it 'updates the data in the given field' do
        first_key = Setting.Locations.keys.first
        first_field = Setting.Locations[first_key].first.first

        expect(Setting.Locations[first_key][first_field]).not_to eq('A new name')
        fill_in "setting[Locations][#{first_key}][#{first_field}]", with: 'A new name'
        click_button "Update #{first_key} Settings"

        expect(Setting.find_by_var('Locations').value[first_key][first_field]).to eq('A new name')
      end

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
        expect(page).to have_css('div.tab-pane#TEST2')
        expect(Setting.find_by_var('Locations').value.keys).to include(:TEST2)
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
      before :each do
        visit edit_setting_path('Rooms')
      end

      it 'has sub-tabs for each location' do
        find_sub_tabs('Rooms')
      end

    end

    context '+/- Setting tab' do
      before :each do
        visit edit_setting_path('new')
      end

      it 'has a form for adding new setting sections' do
        expect(page).to have_css('form#new_setting')
        expect(page).to have_field('setting[new][new_location]')
      end

      it 'has a form for deleting existing setting sections' do
        expect(page).to have_field('setting[new][remove_location]')
      end
    end
  end

end
