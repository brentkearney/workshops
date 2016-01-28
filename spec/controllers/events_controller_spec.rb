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

  describe '#my_events' do
    context 'as an unauthenticated user' do
      it 'redirects to sign-in page' do
        get :my_events

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated user' do
      let(:person) { build(:person) }
      let(:user) { build(:user, person: person, role: 'member') }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'responds with success code' do
        get :my_events

        expect(response).to be_success
      end

      it 'assigns @heading to "My Events"' do
        get :my_events

        expect(assigns(:heading)).to eq('My Events')
      end

      it "assigns @events to user's events" do
        event = create(:event)
        create(:membership, person: person, event: event)

        get :my_events

        expect(assigns(:events)).to match_array(event)
      end

      it "@events excludes events that the user is not a member of" do
        event1 = create(:event)
        event2 = create(:event)
        event3 = create(:event)
        create(:membership, person: person, event: event1)

        get :my_events

        expect(assigns(:events)).to match_array(event1)
      end

      it '@events only includes events with appropriate attendance status' do
        event1 = create(:event)
        event2 = create(:event)
        event3 = create(:event)
        event4 = create(:event)
        event5 = create(:event)
        create(:membership, person: person, event: event1, attendance: 'Invited')
        create(:membership, person: person, event: event2, attendance: 'Confirmed')
        create(:membership, person: person, event: event3, attendance: 'Undecided')
        create(:membership, person: person, event: event4, attendance: 'Declined')
        create(:membership, person: person, event: event5, attendance: 'Not Yet Invited')

        get :my_events

        expect(assigns(:events)).to match_array([event1, event2, event3])
      end
    end

  end

  describe '#scope' do
    context ':past' do
      it 'responds with success code' do
        get :scope, { scope: :past }

        expect(response).to be_success
      end

      it 'renders :index' do
        get :scope, { scope: :past }

        expect(response).to render_template(:index)
      end

      it 'assigns @heading to "Past Events"' do
        get :scope, { scope: :past }

        expect(assigns(:heading)).to eq('Past Events')
      end

      it 'assigns @events only with events from the past' do
        past_event = create(:event, start_date: Date.today.prev_month.prev_week(:sunday),
                                end_date: Date.today.prev_month.prev_week(:sunday) + 5.days)
        current_event = create(:event, start_date: Date.today.prev_week(:sunday),
                        end_date: Date.today.prev_week(:sunday) + 5.days)
        future_event = create(:event, start_date: Date.today.next_week(:sunday),
                                end_date: Date.today.next_week(:sunday) + 5.days)
        get :scope, { scope: :past }

        expect(assigns(:events)).to match_array(past_event)
      end
    end

    context ':future' do
      it 'responds with success code' do
        get :scope, { scope: :future }

        expect(response).to be_success
      end

      it 'renders :index' do
        get :scope, { scope: :future }

        expect(response).to render_template(:index)
      end

      it 'assigns @heading to "Future Events"' do
        get :scope, { scope: :future }

        expect(assigns(:heading)).to eq('Future Events')
      end

      it 'assigns @events only with the current event and future events' do
        past_event = create(:event, start_date: Date.today.prev_month.prev_week(:sunday),
                            end_date: Date.today.prev_month.prev_week(:sunday) + 5.days)
        current_event = create(:event, start_date: Date.today.prev_week(:sunday),
                               end_date: Date.today.prev_week(:sunday) + 5.days)
        future_event = create(:event, start_date: Date.today.next_week(:sunday),
                              end_date: Date.today.next_week(:sunday) + 5.days)

        get :scope, { scope: :future }

        expect(assigns(:events)).to match_array([current_event, future_event])
      end
    end

    context ':year' do
      let(:year) { Date.today.strftime("%Y") }

      it 'responds with success code' do
        get :scope, { scope: :year, format: year }

        expect(response).to be_success
      end

      it 'renders :index' do
        get :scope, { scope: :year, format: year }

        expect(response).to render_template(:index)
      end

      it '(assigns @heading to "[Year] Events"' do
        get :scope, { scope: :year, format: year }

        expect(assigns(:heading)).to eq("#{year} Events")
      end
    end
  end
end