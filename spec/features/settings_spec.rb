# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Settings page', type: :feature do
  before do
    load "#{Rails.root}/spec/support/settings.rb"
  end

  def find_sub_tabs(section)
    Setting.find_by_var('Locations').value.keys.each do |tab|
      visit edit_setting_path(section)
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
      @person.destroy if @person
    end

    it 'has tabs for each Setting section' do
      visit settings_path

      Setting.get_all.keys.each do |tab|
        expect(page).to have_link(tab.titleize)
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
            application_email webmaster_email sysadmin_email code_pattern
            academic_status app_url event_types salutations event_types)

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

      it 'can add new fields' do
        fill_in "setting[Site][new_field]", with: 'Test'
        click_button "Update Settings"

        expect(page.body).to have_field("setting[Site][Test]")
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
          properties.each do |field, _value|
            field_name = "setting[Locations][#{location}][#{field}]"
            expect(page).to have_field(field_name)
          end
        end
      end

      it 'the timezone field is a drop-down of available time zones' do
        location = Setting.Locations.keys.first
        tz_select = "setting[Locations][#{location}][Timezone]"
        zones = []
        ActiveSupport::TimeZone.us_zones.each do |tz|
          zones << tz.to_s
        end

        expect(page.body).to have_select(tz_select, with_options: zones)
      end

      it 'the correct timezone is selected in the Timezone drop-down' do
        location = Setting.Locations.keys.first
        tz_select = "select#setting_Locations_#{location}_Timezone"
        timezone = Setting.Locations[location]['Timezone']

        expect(find(:css, tz_select).value).to eq(timezone)
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
        key = Setting.Locations.keys.last
        fill_in "setting[Locations][#{key}][new_key]", with: 'FOO'
        click_button "Update #{key} Settings"

        visit edit_setting_path('Emails')
        expect(page.body).not_to have_css("div.tab-pane##{key}")
        expect(page.body).to have_css('div.tab-pane#FOO')

        visit edit_setting_path('Rooms')
        expect(page.body).not_to have_css("div.tab-pane##{key}")
        expect(page.body).to have_css('div.tab-pane#FOO')
      end

      it 'has a "+/- Location" tab to add new locations' do
        click_link '+/- Location'
        fill_in 'setting[Locations][new_location]', with: 'TEST2'
        click_button 'Create New Location'

        expect(page).to have_text('Setting has been updated')
        expect(page).to have_css('div.tab-pane#TEST2')
        expect(Setting.find_by_var('Locations').value.keys).to include('TEST2')
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
        Setting.Locations = Setting.Locations.merge('XYZ' => Setting.Locations[key])

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
        visit new_setting_path('Site')
      end

      it 'adds a new setting section' do
        fill_in 'setting[var]', with: 'NewSection'
        click_button 'Add Setting'

        expect(page.body).to have_text 'Added "NewSection" setting!'
        expect(page.body).to have_css('li#NewSection')
        expect(Setting.find_by_var('NewSection')).not_to be_nil
      end

      it 'new sections have sub-tabs for each location' do
        fill_in 'setting[var]', with: 'NewSection2'
        click_button 'Add Setting'

        find_sub_tabs('NewSection2')
      end

      it 'new sections have a form for adding new fields' do
        fill_in 'setting[var]', with: 'NewSection3'
        click_button 'Add Setting'

        visit edit_setting_path('NewSection3')

        Setting.find_by_var('Locations').value.keys.each do |tab|
          expect(page.body).to have_field("setting[NewSection3][#{tab}][new_field]")
        end
      end

      it 'new fields can be added to new sections' do
        key = Setting.Locations.keys.first
        fill_in 'setting[var]', with: 'NewSection4'
        click_button 'Add Setting'

        visit edit_setting_path('NewSection4')
        fill_in "setting[NewSection4][#{key}][new_field]", with: 'Test'
        click_button "Update #{key} Settings"

        expect(page.body).to have_field("setting[NewSection4][#{key}][Test]")
      end

      it 'disallows duplicate Setting names' do
        fill_in 'setting[var]', with: 'Site'
        click_button 'Add Setting'

        expect(page.body).to have_css('div.alert-error',
          text: 'Error saving setting: Setting Name must be unique')
      end

      it 'disallows blank name field' do
        click_button 'Add Setting'

        expect(page.body).to have_css('div.alert-error',
          text: 'Error saving setting: Setting Name must not be blank')
      end

      it 'deletes a setting section' do
        fill_in 'setting[var]', with: 'DeleteMe'
        click_button 'Add Setting'

        visit new_setting_path
        select 'DeleteMe', from: 'setting[id]'
        click_button 'Delete Setting'

        expect(page.body).to have_css('div.alert-notice',
          text: 'Deleted "DeleteMe" setting!')
        expect(Setting.find_by_var('DeleteMe')).to be_nil
      end
    end
  end
end
