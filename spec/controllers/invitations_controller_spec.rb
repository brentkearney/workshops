# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe InvitationsController, type: :controller do
  before do
    @past = create(:event, past: true)
    @current = create(:event, current: true)
    @future = create(:event, future: true)
  end

  describe 'GET #index' do
    it 'redirects to #new' do
      get :index
      expect(response).to redirect_to(invitations_new_path)
    end
  end

  describe 'GET #new' do
    before :each do
      get :new
    end

    it 'responds with success code' do
      expect(response).to be_success
    end

    it 'renders :new template' do
      expect(response).to render_template(:new)
    end

    it 'assigns future events to @events' do
      expect(assigns(:events)).to include(@future)
      expect(assigns(:events)).not_to include(@current)
      expect(assigns(:events)).not_to include(@past)
    end

    it 'assigns InvitationForm to @invitation' do
      expect(assigns(:invitation)).to be_a(InvitationForm)
    end
  end

  describe 'POST #create' do
    before do
      authenticate_for_controllers
      @user.admin!
      @event = @future
      @event.memberships.destroy_all
      @membership = create(:membership, event: @event, attendance: 'Invited')
      @form_params = {'invitation': {
          'event': @event.code,
          'email': @membership.person.email
      }}
    end

    it 'assigns @invitation using params' do
      post :create, @form_params
      expect(assigns(:invitation)).to be_a(InvitationForm)
    end

    context 'valid params' do
      before do
        post :create, @form_params
      end

      it 'redirects to invitations_new_path' do
        expect(response).to redirect_to(invitations_new_path)
      end

      it 'assigns success message' do
        expect(flash[:success]).to be_present
      end

      it 'does not assign @events' do
        expect(assigns(:events)).to be_falsey
      end

      it 'does not add errors to @invitation' do
        expect(assigns(:invitation).errors).to be_empty
      end

      it 'sends invitation' do
        invitation = spy('invitation')
        allow(Invitation).to receive(:new).and_return(invitation)

        post :create, @form_params

        expect(invitation).to have_received(:send_invite)
      end
    end

    context 'invalid params' do
      before do
        @form_params = {'invitation' => {'event' => 'foo', 'email' => 'bar'}}
        post :create, @form_params
      end

      it 'assigns @events' do
        expect(assigns(:events)).not_to be_empty
      end

      it 'renders :new template' do
        expect(response).to render_template(:new)
      end

      it 'adds errors to @invitation' do
        expect(assigns(:invitation).errors).not_to be_empty
      end

      it 'does not send invitation' do
        invitation = spy('invitation')
        allow(Invitation).to receive(:new).and_return(invitation)

        post :create, @form_params

        expect(invitation).not_to have_received(:send_invite)
      end
    end
  end

  describe 'GET #send_invite' do
    before do
      authenticate_for_controllers
      @user.admin!
      @event = @future
      @event.memberships.destroy_all
      @membership = create(:membership, event: @event, attendance: 'Invited')
    end

    it 'allows admins' do
      get :send_invite, membership_id: @membership.id
      expect(flash[:success]).to be_present
    end

    it 'allows staff' do
      @user.staff!
      get :send_invite, membership_id: @membership.id
      expect(flash[:success]).to be_present
      @user.admin!
    end

    it 'does not allow non-member users' do
      @user.member!
      get :send_invite, membership_id: @membership.id
      expect(flash[:error]).to be_present
      @user.admin!
    end

    it 'does not allow member users' do
      @user.member!
      original_person = @membership.person
      @membership.person = @user.person
      @membership.attendance = 'Confirmed'
      @membership.role = 'Participant'
      @membership.save

      get :send_invite, membership_id: @membership.id
      expect(flash[:error]).to be_present
      @user.admin!
      @membership.person = original_person
      @membership.save
    end

    it 'allows members that are organizers' do
      @user.member!
      original_person = @membership.person
      @membership.person = @user.person
      @membership.role = 'Organizer'
      @membership.save

      get :send_invite, membership_id: @membership.id
      expect(flash[:success]).to be_present
      @user.admin!
      @membership.person = original_person
      @membership.save
    end

    context 'invalid parameter' do
      before do
        get :send_invite, membership_id: '69 '
      end

      it 'redirects to root_path' do
        expect(response).to redirect_to(root_path)
      end

      it 'assigns error message' do
        expect(flash[:error]).to be_present
      end
    end

    context 'valid parameter' do
      before do
        get :send_invite, membership_id: @membership.id
      end

      it 'redirects to event_memberships_path' do
        event = @membership.event
        expect(response).to redirect_to(event_memberships_path(event))
      end

      it 'assigns success message' do
        expect(flash[:success]).to be_present
      end

      it 'sends invitation' do
        invitation = spy('invitation')
        allow(Invitation).to receive(:new).and_return(invitation)

        get :send_invite, membership_id: @membership.id

        expect(invitation).to have_received(:send_invite)
      end
    end
  end

  describe 'GET #send_all_invites' do
    before do
      authenticate_for_controllers
      @user.admin!
      @event = @future
      @membership = create(:membership, event: @event, attendance: 'Not Yet Invited')
    end

    it 'allows admins' do
      get :send_all_invites, event_id: @event.id
      expect(flash[:success]).to be_present
    end

    it 'allows staff' do
      @user.staff!
      get :send_all_invites, event_id: @event.id
      expect(flash[:success]).to be_present
      @user.admin!
    end

    it 'does not allow non-member users' do
      @user.member!
      get :send_all_invites, event_id: @event.id
      expect(flash[:error]).to be_present
      @user.admin!
    end

    it 'does not allow member users' do
      @user.member!
      original_person = @membership.person
      @membership.person = @user.person
      @membership.attendance = 'Confirmed'
      @membership.role = 'Participant'
      @membership.save

      get :send_all_invites, event_id: @event.id
      expect(flash[:error]).to be_present
      @user.admin!
      @membership.person = original_person
      @membership.save
    end

    it 'allows members that are organizers' do
      @user.member!
      original_person = @membership.person
      @membership.person = @user.person
      @membership.role = 'Organizer'
      @membership.save

      get :send_all_invites, event_id: @event.id
      expect(flash[:success]).to be_present
      @user.admin!
      @membership.person = original_person
      @membership.save
    end

    context 'invalid parameter' do
      before do
        get :send_all_invites, event_id: '69'
      end

      it 'redirects to root_path' do
        expect(response).to redirect_to(root_path)
      end

      it 'assigns error message' do
        expect(flash[:error]).to be_present
      end
    end

    context 'valid parameter' do
      before do
        get :send_all_invites, event_id: @event.id
      end

      it 'redirects to event_memberships_path' do
        event = @membership.event
        expect(response).to redirect_to(event_memberships_path(event))
      end

      it 'assigns success message' do
        expect(flash[:success]).to be_present
      end

      it 'sends invitation' do
        @membership.role = 'Participant'
        @membership.attendance = 'Not Yet Invited'
        @membership.save

        get :send_all_invites, event_id: @event.id

        expect(Invitation.last.membership).to eq(@membership)
      end
    end
  end
end
