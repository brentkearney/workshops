# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Events Admin Dashboard', type: :feature do
  before do
  	@member_user = create(:user, role: 'member')
    @staff_user = create(:user, :staff)
    @admin_user = create(:user, :admin)
    @super_admin_user = create(:user, :super_admin)  
  end

  after(:each) do
    Warden.test_reset!
  end

  context 'As a not-logged in user' do
    before do
      visit 'admin/events'
    end

    it "should redirect to root path" do
      expect(page).to redirect_to root_path
      expect(page).to have_content("You dont have permission")
    end
  end

  context 'As a staff user' do
    before do
      login_as @member_user, scope: :user
      visit 'admin/events'
    end

    it "should redirect to root path" do
      expect(page).to redirect_to root_path
      expect(page).to have_content("You dont have permission")
    end
  end

  context 'As an staff user' do
    before do
      login_as @staff, scope: :user
    end

    it "should display admin events dashboard" do
	end
  end

  context 'As an admin user' do
    before do
      login_as @admin_user, scope: :user
    end
    it "should display admin events dashboard" do
	end
  end
end