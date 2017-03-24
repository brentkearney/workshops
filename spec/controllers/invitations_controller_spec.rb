# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe InvitationsController, type: :controller do
  describe 'GET #index' do
    it 'redirects to #new' do
      get :index
      expect(response).to redirect_to(invitations_new_path)
    end
  end

  describe 'GET #new' do
    before do
      @past = create(:event, past: true)
      @current = create(:event, current: true)
      @future = create(:event, future: true)
    end

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
      expect(assigns(:events)).to include(@current, @future)
      expect(assigns(:events)).not_to include(@past)
    end

    it 'assigns InvitationForm to @invitation' do
      expect(assigns(:invitation)).to be_a(InvitationForm)
    end
  end

  describe 'POST #create' do
    before do
      @event = create(:event, future: true)
    end

    it 'assigns @invitation using params'
    it 'validates params'
    context 'valid params' do
      it 'sends invitation'
    end

    context 'invalid params' do
      it 'assigns @events'
      it 'renders :new'
    end
  end
end
