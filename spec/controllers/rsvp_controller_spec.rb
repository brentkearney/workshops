# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe RsvpController, type: :controller do
  describe 'GET #index' do
    context 'without one-time-password (OTP) in the url' do
      it 'redirects to new RSVP page' do
        get :index
        expect(response).to redirect_to(rsvp_new_path)
      end
    end

    context 'with valid one-time-password (OTP) in the url' do
      it 'validates the one-time-password (OTP) via legacy db' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)
        allow(lc).to receive(:check_rsvp).with('123').and_return(lc.valid_otp)

        get :index, { otp: '123' }

        expect(assigns(:message)).to include('attendance' => 'Confirmed')
      end
    end

    context 'with invalid one-time-password (OTP) in the url' do
      it 'returns denied message' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)
        allow(lc).to receive(:check_rsvp).with('123').and_return(lc.invalid_otp)

        get :index, { otp: '123' }

        expect(assigns(:message)).to include('denied' =>
                                             'Invalid invitation code.')
      end
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
  end

  describe 'POST #new' do
    before do
      @event = create(:event, future: true)
    end

    it 'validates email' do
      post :new, { event: @event.code, email: 'foo' }
      expect(response).to render_template('new')
      expect(assigns(:flash)).to include(:error)
    end
  end
end
