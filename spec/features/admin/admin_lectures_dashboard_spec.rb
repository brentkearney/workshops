# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Lectures Admin Dashboard', type: :feature do
  before do
  	@event = create(:event)
  	person = create(:person)
  	membership = create(:membership, event: @event, person: person, role: 'Organizer')

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
      visit 'admin/lectures'
    end

    it "should redirect to sign_in" do
      expect(page).to have_current_path('/users/sign_in')
      expect(page).to have_content("You need to sign in or sign up before continuing")
    end
  end

  context 'As a member user' do
    before do
      login_as @member_user, scope: :user
      visit 'admin/lectures'
    end

    it "should redirect to root path" do
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Not Authorized")
    end
  end

  context 'As a staff user' do
    before do
      login_as @staff_user, scope: :user
      visit 'admin/lectures'
    end

    it "should redirect to root path" do
      expect(page).to have_current_path(events_future_path(@member_user.location))
    end
  end

  context 'As a admin user' do
    before do
      login_as @admin_user, scope: :user
      visit 'admin/lectures'
    end

    it "should display admin lectures dashboard" do
      expect(page).to have_current_path(admin_lectures_path)
    end
  end

  context 'As a super_admin user' do
    before do
      login_as @super_admin_user, scope: :user
      visit 'admin/lectures'
    end

    it "should display admin lectures dashboard" do
      expect(page).to have_current_path(admin_lectures_path)
    end
  end
end