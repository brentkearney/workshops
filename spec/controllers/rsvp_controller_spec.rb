# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe RsvpController, type: :controller do
  describe 'GET #index' do
    context 'without one-time-password (OTP) in the url' do
      it 'redirects to new invitations page' do
        get :index
        expect(response).to redirect_to(invitations_new_path)
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
end
