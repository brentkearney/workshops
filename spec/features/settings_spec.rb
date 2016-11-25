# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Settings page', type: :feature do

  it 'initializes with some default settings' do
    expect(Setting.Site).not_to be_nil
    expect(Setting.Site).not_to be_empty
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

    it 'has no "+/- Setting" link for non-admin users' do
      expect(page.body).not_to have_link('+/- Setting')
    end
  end

  context 'As an admin user' do
    before do
      @person = create(:person)
      @user = create(:user, person: @person, role: 'admin')
      login_as @user, scope: :user
    end

    it 'has an "+/- Setting" link' do
      visit settings_path

      expect(page.body).to have_link('+/- Setting')
    end

    it '"+/- Setting" link opens new_setting_path' do
      visit settings_path
      click_link '+/- Setting'

      expect(current_path).to eq(new_setting_path)
    end

    it '"+/- Setting" section has a form that adds settings' do
      visit new_setting_path

      fill_in 'Setting Name:', with: 'Testing'
      click_button 'Add Setting'

      expect(page.body).to have_text('Added "Testing" setting!')
      expect(page.body).to have_link('Testing')
    end

    it '"+/- Setting" section has a form that deletes settings' do
      Setting.Testing = { 'foo': 'bar'}
      visit new_setting_path

      select 'Testing', from: 'setting[id]'
      click_button 'Delete Setting'

      expect(page.body).to have_text('Deleted "Testing" setting!')
      expect(page.body).not_to have_link('Testing')
    end


    it 'has a link (tab) for each Setting name' do
      visit settings_path

      Setting.get_all.each do |type, value|
        puts "Setting: #{type}"
        expect(page).to have_link(type)
      end
    end

    it 'setting sections have an "Add New Field" form' do
      Setting.Testing = { 'foo': 'bar'}

      visit edit_setting_path('Testing')

      expect(page).to have_text("Add New Field to \"Testing\"")
      expect(page).to have_field("setting[Testing][new_field]")
      expect(page).to have_field("setting[Testing][new_value]")
    end

    it 'the "Add New Field" form adds new fields' do
      Setting.foo = { 'bar': 'baz1' }

      visit edit_setting_path('foo')
      fill_in 'setting[foo][new_field]', with: 'Breakfast'
      fill_in 'setting[foo][new_value]', with: 'Lunch'
      click_button 'Update Settings'

      expect(page).to have_text('Setting has been updated')
      expect(find_field('setting[foo][Breakfast]').value).to eq('Lunch')
    end

    it 'allows the addition of array values' do
      Setting.foo = { 'bar': 'baz1' }

      visit edit_setting_path('foo')
      fill_in 'setting[foo][new_field]', with: 'Breakfast'
      fill_in 'setting[foo][new_value]', with: '[Lunch, Dinner, Desert]'
      click_button 'Update Settings'

      expect(page).to have_text('Setting has been updated')
      setting = Setting.find_by_var('foo')
      expect(setting.value['Breakfast'].class).to eq(Array)
    end
  end
end
