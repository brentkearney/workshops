# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Accessing the Settings section', type: :feature do

  context 'External users' do
    it 'disallows users who are not logged in' do
      visit settings_path

      expect(page.body).to have_text('You need to sign in or sign up')
      expect(current_path).to eq(user_session_path)
    end
  end

  context 'Internal users' do
    before do
      @person = create(:person)
      @user = create(:user, person: @person, role: 'member')
      login_as @user, scope: :user

      visit settings_path
    end

    it 'allows logged-in users' do
      expect(current_path).to eq(settings_path)
    end

    it 'shows user profile settings' do
      expect(page.body).to have_text('Gender:')
      expect(page.body).to have_text(@person.name)
      expect(page.body).to have_text('Affiliation:')
      expect(page.body).to have_text(@person.affiliation)
      expect(page.body).to have_text('Email:')
      expect(page.body).to have_text(@person.email)
    end
  end

end
