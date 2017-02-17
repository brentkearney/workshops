# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Settings page', type: :feature do
  before do
    Setting.destroy_all
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
      before :each do
        visit edit_setting_path('Site')
      end

      it 'shows the fields of the Site settings' do
        Setting.Site.keys.each do |field|
          expect(page).to have_field("setting[Site][#{field}]") unless field.empty?
        end
      end

      it 'has the minimum necessary fields for the app to function' do
        required_fields = %w(title footer events_url legacy_person legacy_api
            application_email webmaster_email sysadmin_email)

        required_fields.each do |field|
          expect(page).to have_field("setting[Site][#{field}]")
        end
      end

      it 'updates data' do
        fill_in 'setting[Site][title]', with: 'Test Title'
        click_button 'Update Settings'

        expect(page).to have_text('Setting has been updated')
        title = Setting.Site['title']
        expect(title).to eq('Test Title')
      end

      it 'accepts array values' do
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

      it 'Setting.Emails returns same value as Setting.find_by_var(Emails)' do
        fill_in "setting[Emails][EO][program_coordinator]", with: 'test@test.ca'
        click_button 'Update EO Settings'

        new_setting = Setting.find_by_var('Emails').value
        expect(Setting.Locations[:program_coordinator]).to eq(new_setting[:program_coordinator])
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
        fill_in "setting[Locations][#{first_key}][#{first_field}]", with: 'A new name'
        click_button "Update #{first_key} Settings"

        expect(Setting.Locations[first_key][first_field]).to eq('A new name')
      end

      it '"Location code" field updates the key representing that location' do
        fill_in "setting[Locations][EO][new_key]", with: 'TEST'
        click_button 'Update EO Settings'

        expect(page).to have_text('Setting has been updated')
        expect(Setting.Locations.keys).not_to include('EO')
        expect(Setting.Locations.keys).to include('TEST')
      end

      it 'updating the location code updates it for all sections' do
        fill_in "setting[Locations][EO][new_key]", with: 'TEST'
        click_button 'Update EO Settings'

        click_link 'Emails'
        expect(page.body).not_to have_css('div.tab-pane#EO')
        expect(page.body).to have_css('div.tab-pane#TEST')
        click_link 'Rooms'
        expect(page.body).not_to have_css('div.tab-pane#EO')
        expect(page.body).to have_css('div.tab-pane#TEST')
      end

      it 'has a "+/- Location" tab to add new locations' do
        click_link '+/- Location'
        fill_in 'setting[Locations][new_location]', with: 'TEST2'
        click_button 'Create New Location'

        expect(page).to have_text('Setting has been updated')
        expect(page).to have_css('div.tab-pane#TEST2')
        expect(Setting.find_by_var('Locations').value.keys).to include(:TEST2)
      end

      it 'adds the new location to the other Setting sections as well' do
        click_link '+/- Location'
        fill_in 'setting[Locations][new_location]', with: 'TEST5'
        click_button 'Create New Location'

        click_link 'Emails'
        expect(page.body).to have_css('div.tab-pane#TEST5')
        click_link 'Rooms'
        expect(page.body).to have_css('div.tab-pane#TEST5')
      end

      it 'has a "+/- Location" tab to remove locations' do
        key = Setting.Locations.keys.first
        Setting.Locations = Setting.Locations.merge(:XYZ => Setting.Locations[key])

        click_link '+/- Location'
        select 'XYZ', from: 'setting[Locations][remove_location]'
        click_button 'Delete Location'

        visit edit_setting_path('Locations')
        expect(page).not_to have_css('div.tab-pane#XYZ')
        click_link 'Emails'
        expect(page.body).not_to have_css('div.tab-pane#XYZ')
        click_link 'Rooms'
        expect(page.body).not_to have_css('div.tab-pane#XYZ')
      end

      it 'Setting.Locations returns same value as Setting.find_by_var(Locations)' do
        fill_in "setting[Locations][EO][new_key]", with: 'TEST'
        click_button 'Update EO Settings'

        new_setting = Setting.find_by_var('Locations').value
        expect(Setting.Locations[:TEST]).to eq(new_setting[:TEST])
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
