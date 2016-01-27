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
      let(:person) { FactoryGirl.build(:person) }
      let(:user) { FactoryGirl.build(:user, person: person) }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'responds with success code' do
        get :index

        expect(response).to be_success
      end

      it 'assigns @heading to "Your Events"' do
        get :index

        expect(assigns(:heading)).to eq('Your Events')
      end

      it "assigns the authenticated user's events to @events" do
        event = FactoryGirl.build(:event)
        # person defined above, associated to authenticated user
        membership = FactoryGirl.build(:membership, person: person, event: event)

        get :index

        expect(assigns(:events)).to eq(person.events)
      end
    end
  end

  describe '#all' do
    
  end
end