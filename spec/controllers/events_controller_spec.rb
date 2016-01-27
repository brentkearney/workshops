# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  describe '#index' do
    it 'responds with success code' do
      get :index

      expect(response).to be_success
    end

    it 'assigns @heading to "All Events"' do
      get :index

      expect(assigns(:heading)).to eq('All Events')
    end

    it 'assigns @events to all events' do
      event = create(:event)

      get :index

      expect(assigns(:events)).to match_array(event)
    end

    context 'as an unauthenticated user' do
      it '@events excludes template events' do
        event1 = create(:event, template: false)
        event2 = create(:event, template: true)

        get :index

        expect(assigns(:events)).to match_array(event1)
      end
    end

    context 'as an authenticated user' do
      let(:person) { build(:person) }
      let(:user) { build(:user, person: person, role: 'member') }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context 'member' do
        before do
          user.member!
        end

        it '@events excludes template events' do
          event1 = create(:event, template: false)
          event2 = create(:event, template: true)

          get :index

          expect(assigns(:events)).to match_array(event1)
        end
      end

      context 'staff' do
        before do
          user.staff!
        end

        it "@events includes only events at the user's location" do
          event1 = create(:event, location: user.location)
          event2 = create(:event, location: 'elsewhere')

          get :index

          expect(assigns(:events)).to match_array(event1)
        end

        it "@events includes template events" do
          event1 = create(:event, template: false, location: user.location)
          event2 = create(:event, template: true, location: user.location)

          get :index

          expect(assigns(:events)).to match_array([event1, event2])
        end

        it "@events excludes template events that are not at user's location" do
          event1 = create(:event, template: false, location: user.location)
          event2 = create(:event, template: true, location: user.location)
          event3 = create(:event, template: true, location: 'elsewhere')

          get :index

          expect(assigns(:events)).to match_array([event1, event2])
        end
      end

      context 'admin user' do
        before do
          user.admin!
        end

        it '@events includes all events including templates' do
          event1 = create(:event, template: false, location: user.location)
          event2 = create(:event, template: true, location: user.location)
          event3 = create(:event, template: true, location: 'elsewhere')
          event4 = create(:event, template: false, location: 'elsewhere')

          get :index

          expect(assigns(:events)).to match_array([event1, event2, event3, event4])
        end
      end

    end

  end

end