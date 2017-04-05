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

    context 'with valid OTP in the url' do
      before do
        @invitation = create(:invitation)
      end

      it 'validates the OTP via legacy db' do
        allow_any_instance_of(InvitationChecker).to receive(:check_legacy_database).and_return(@invitation)

        get :index, { otp: '123' }

        expect(assigns(:invitation)).to be_a(Invitation)
      end

      it 'validates the OTP via local db and renders index' do
        get :index, { otp: @invitation.code }

        expect(assigns(:invitation)).to eq(@invitation)
        expect(response).to render_template(:index)
      end

      it '#yes'
      it '#no'
      it '#maybe'
    end

    context 'with invalid OTP in the url' do
      it 'redirects to new invitations page' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)
        allow(lc).to receive(:check_rsvp).with('123').and_return(lc.invalid_otp)

        get :index, { otp: '123' }

        expect(response).to redirect_to(invitations_new_path)
        expect(flash[:warning]).to include('That invitation code was not found')
      end
    end
  end
end
