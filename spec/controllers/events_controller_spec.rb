# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  describe "#index" do
    context 'without authentication' do
      it 'redirects to sign_in path' do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with authentication' do
      it "allows authenticated access" do
        user = FactoryGirl.build(:user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)

        get :index

        expect(response).to be_success
      end
    end

  end
end