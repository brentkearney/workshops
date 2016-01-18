# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do

  let(:all_events) { 10.times { FactoryGirl.create(:event) } }

  before do
    Event.destroy_all
    authenticate_for_controllers # sets @user, @person, @event, @membership
    all_events
  end

  describe "GET #index" do

    context 'if user is a participant' do
      before do
        @user.member!
        @person.memberships.each do |m|
          m.role = 'Participant'
          m.attendance = 'Confirmed'
          m.save
        end
        get :index
        expect(response.status).to eq(302)
      end

      it 'redirects to welcome page for participants' do
        expect(response).to redirect_to(welcome_member_path)
      end

      it 'assigns @events to the participants events' do
        get :participants
        events = @user.person.events
        expect(assigns(:events)).to eq(events)
      end

    end

    context 'if user is an organizer' do
      before do
        @user.member!
        @membership = @user.person.memberships.first
        @membership.role = 'Organizer'
        @membership.save!
        get :index
        expect(response.status).to eq(302)
      end

      it 'redirects to welcome page for organizers' do
        expect(response).to redirect_to(welcome_organizers_path)
      end

      it 'assigns @events to the organizers events' do
        get :organizers
        events = @user.person.events
        expect(assigns(:events)).to eq(events)
      end

    end


    context 'if user is an admin' do
      before do
        @user.admin!
        get :index
        expect(response.status).to eq(302)
      end

      it 'redirects to welcome page for admins' do
        expect(response).to redirect_to(welcome_admin_path)
      end

      after do
        @user.member!
      end
    end

    context 'if user is a super-admin' do
      before do
        @user.super_admin!
        get :index
        expect(response.status).to eq(302)
      end

      it 'redirects to welcome page for admins' do
        expect(response).to redirect_to(welcome_admin_path)
      end

      after do
        @user.member!
      end
    end

    context 'if user is a staff member' do
      before do
        @user.staff!
        get :index
        expect(response.status).to eq(302)
      end

      it 'redirects to welcome page for staff' do
        expect(response).to redirect_to(welcome_staff_path)
      end

      after do
        @user.member!
      end
    end

  end
end