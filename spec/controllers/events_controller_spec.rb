# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  before do
    Schedule.delete_all
    Membership.delete_all
    Event.delete_all
  end

  describe '#index' do
    it 'responds with success code' do
      get :index

      expect(response).to be_success
    end

    it 'assigns @events to all events' do
      event = create(:event)

      get :index

      expect(assigns(:events)).to match_array(event)
    end

    def excludes_template_events_test
      event1 = create(:event, template: false)
      create(:event, template: true)

      get :index

      expect(assigns(:events)).to match_array(event1)
    end

    context 'as an unauthenticated user' do
      it '@events excludes template events' do
        excludes_template_events_test
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
          excludes_template_events_test
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

  describe '#past' do
    it 'responds with success code' do
      get :past

      expect(response).to be_success
    end

    it 'renders :index' do
      get :past

      expect(response).to render_template(:index)
    end

    it 'assigns @events only with events from the past' do
      past_event = create(:event, past: true)
      current_event = create(:event, current: true)
      future_event = create(:event, future: true)

      get :past

      expect(assigns(:events)).to match_array([past_event])
    end

    context 'with user roles' do
      let(:person) { build(:person) }
      let(:user) { build(:user, person: person) }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)

        @event1 = create(:event, past: true, location: user.location)
        @event2 = create(:event, location: 'elsewhere', start_date: @event1.start_date - 1.week,
                         end_date: @event1.end_date - 1.week)
      end

      it "members: @events includes all past events" do
        user.member!

        get :past

        expect(assigns(:events)).to match_array([@event1, @event2])
      end

      it "staff: @events includes only events at the user's location" do
        user.staff!

        get :past

        expect(assigns(:events)).to match_array([@event1])
      end

      it "admin: @events includes all past events" do
        user.admin!

        get :past

        expect(assigns(:events)).to match_array([@event1, @event2])
      end

      it "super_admin: @events includes all past events" do
        user.super_admin!

        get :past

        expect(assigns(:events)).to match_array([@event1, @event2])
      end
    end
  end

  describe '#future' do
    it 'responds with success code' do
      get :future

      expect(response).to be_success
    end

    it 'renders :index' do
      get :future

      expect(response).to render_template(:index)
    end

    it 'assigns @events only with the current event and future events' do
      past_event = create(:event, past: true)
      current_event = create(:event, current: true)
      future_event = create(:event, future: true)

      get :future

      expect(assigns(:events)).to match_array([current_event, future_event])
    end

    context 'with user roles' do
      let(:person) { build(:person) }
      let(:user) { build(:user, person: person) }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)

        @event1 = create(:event, location: user.location, start_date: Date.today.next_week(:sunday),
                         end_date: Date.today.next_week(:sunday) + 5.days)
        @event2 = create(:event, location: 'elsewhere', start_date: @event1.start_date - 1.week,
                         end_date: @event1.end_date - 1.week)
      end

      it "members: @events includes all future events" do
        user.member!

        get :future

        expect(assigns(:events)).to match_array([@event1, @event2])
      end

      it "staff: @events includes only events at the user's location" do
        user.staff!

        get :future

        expect(assigns(:events)).to match_array([@event1])
      end

      it "admin: @events includes all future events" do
        user.admin!

        get :future

        expect(assigns(:events)).to match_array([@event1, @event2])
      end

      it "super_admin: @events includes all future events" do
        user.super_admin!

        get :future

        expect(assigns(:events)).to match_array([@event1, @event2])
      end
    end
  end

  describe '#year' do
    let(:year) { Date.today.strftime("%Y") }

    it 'responds with success code' do
      get :year, { year: year }

      expect(response).to be_success
    end

    it 'renders :index' do
      get :year, { year: year }

      expect(response).to render_template(:index)
    end

    it "assigns @events to events of [year]" do
      this_year = Date.parse("#{year}-09-01").next_week(:sunday)
      event1 = create(:event, start_date: this_year, end_date: this_year + 5.days)
      last_year = Date.parse("#{year.to_i - 1}-09-01").next_week(:sunday)
      event2 = create(:event, start_date: last_year, end_date: last_year + 5.days)

      get :year, { year: year }

      expect(assigns(:events)).to eq([event1])
    end

    it 'redirects to events_path given an invalid year' do
      %w(2015foo bar2013 wookie 1 12 123).each do |badyear|

        get :year, { year: badyear }

        expect(response).to redirect_to(events_path)
      end
    end
  end

  describe '#location' do
    Setting.Locations.keys.each do |loc|
      context ":#{loc}" do
        let(:location) { loc }

        it 'responds with success code' do
          get :location, { location: location }

          expect(response).to be_success
        end

        it 'renders :index' do
          get :location, { location: location }

          expect(response).to render_template(:index)
        end

        it %Q(assigns @events to events at #{loc} location) do
          event1 = create(:event, location: "#{loc}")
          event2 = create(:event, location: 'Elsewhere')

          get :location, { location: location }

          expect(assigns(:events)).to eq([event1])
        end
      end
    end

    it 'given an invalid location, it uses the first configured location' do
      legit_location = Setting.Locations.keys.first
      event1 = create(:event, location: "#{legit_location}")

      %w(random-place 7th-level-of-hell at-the-pub).each do |place|

        get :location, { location: place }

        expect(assigns(:events)).to eq([event1])
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#kind' do
    Setting.Site['event_types'].each do |type|
      context ":#{type}" do
        let(:kind) { type.parameterize }

        it 'responds with success code' do
          get :kind, { kind: kind }

          expect(response).to be_success
        end

        it 'renders :index' do
          get :kind, { kind: kind }

          expect(response).to render_template(:index)
        end

        it %Q(assigns @events to events of type #{type}) do
          event1 = create(:event, event_type: "#{type}")
          another_type = type
          until another_type != type
            another_type = Setting.Site['event_types'].sample
          end
          event2 = create(:event, event_type: "#{another_type}")

          get :kind, { kind: kind }

          expect(assigns(:events)).to eq([event1])
        end
      end
    end

    it 'given an invalid event type, it assumes the first configured type' do
      legit_type = Setting.Site['event_types'].first
      event1 = create(:event, location: "#{legit_type}")

      %w(lynch-mob circus funeral).each do |invalid_type|

        get :kind, { kind: invalid_type }

        expect(assigns(:events)).to eq([event1])
        expect(response).to render_template(:index)
      end
    end
  end
end
