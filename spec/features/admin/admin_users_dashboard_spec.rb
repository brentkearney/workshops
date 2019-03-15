# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Users Admin Dashboard', type: :feature do
  before do
  	@event = create(:event)
  	person = create(:person)

  	@member_user = create(:user,email: person.email,person: person, role: 0)
    @staff_user = create(:user, :staff)
    @admin_user = create(:user, :admin)
    @super_admin_user = create(:user, :super_admin)
  end

  after(:each) do
    Warden.test_reset!
  end

  context 'As a not-logged in user' do
    before do
      visit 'admin/users'
    end

    it "should redirect to sign_in" do
      expect(page).to have_current_path('/users/sign_in')
      expect(page).to have_content("You need to sign in or sign up before continuing")
    end
  end

  context 'As a member user' do
    before do
      login_as @member_user, scope: :user
      visit 'admin/users'
    end

    it "should redirect to root path" do
      expect(current_path).to eq(events_future_path).or eq(root_path)
      expect(page).to have_content("Access denied")
    end
  end

  context 'As a staff user' do
    before do
      login_as @staff_user, scope: :user
      visit 'admin/users'
    end

    it "should redirect to root path" do
      expect(page).to have_current_path(admin_people_path)
      expect(page).to have_content("Access denied")
    end
  end

  context 'As a admin user' do
    before do
      login_as @admin_user, scope: :user
      visit 'admin/users'
    end

    it "should display admin lectures dashboard" do
      expect(page).to have_current_path(admin_users_path)
    end
  end

  context 'As a super_admin user' do
    before do
      login_as @super_admin_user, scope: :user
      visit 'admin/users'
    end

    it "should display admin lectures dashboard" do
      expect(page).to have_current_path(admin_users_path)
    end
  end
end
