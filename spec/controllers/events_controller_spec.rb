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
      @past_event = create(:event, past: true)
      @event = create(:event, current: true)
      @future_event = create(:event, future: true)
    end


    describe '#index' do
      it 'responds with success code' do
        get :index

        expect(response).to be_successful
      end

      it 'assigns @events to all events' do
        get :index

        expect(assigns(:events)).to eq([@past_event, @event, @future_event])
      end

      def excludes_template_events_test
        @future_event.template = true
        @future_event.save

        get :index

        expect(assigns(:events)).to eq([@past_event, @event])

        @future_event.template = false
        @future_event.save
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
            user.location = 'F00'
            user.save
          end

          it "@events includes all events" do
            get :index

            expect(assigns(:events)).to eq([@past_event, @event, @future_event])
          end

          it "@events includes template events at user's location" do
            org_loc = @event.location
            @event.location = user.location
            @event.template = true
            @event.save

            get :index

            expect(assigns(:events)).to include(@event)

            @event.location = org_loc
            @event.template = false
            @event.save
          end

          it "@events excludes template events that are not at user's location" do
            @event.template = true
            @event.save
            expect(@event.location).not_to eq(user.location)

            get :index

            expect(assigns(:events)).not_to include(@event)

            @event.template = false
            @event.save
          end
        end

        context 'admin user' do
          before do
            user.admin!
          end

          it '@events includes all events including templates' do
            org_loc = @past_event.location
            @past_event.location = 'elsewhere'
            @past_event.save
            @event.template = true
            @event.save
            org_loc2 = @future_event.location
            @future_event.save

            get :index

            expect(assigns(:events)).to match_array([@past_event, @event, @future_event])

            @past_event.location = org_loc
            @past_event.save
            @future_event.location = org_loc2
            @future_event.save
            @event.template = false
            @event.save
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

          expect(response).to be_successful
        end

        it "assigns @events to user's events" do
          create(:membership, person: person, event: @event)

          get :my_events

          expect(assigns(:events)).to match_array(@event)
        end

        it "@events excludes events that the user is not a member of" do
          create(:membership, person: person, event: @future_event)

          get :my_events

          expect(assigns(:events)).to eq([@future_event])
        end

        it '@events only includes events with appropriate attendance status' do
          m1 = create(:membership, person: person, event: @past_event, attendance: 'Invited')
          m2 = create(:membership, person: person, event: @event, attendance: 'Confirmed')
          m3 = create(:membership, person: person, event: @future_event, attendance: 'Undecided')

          get :my_events

          expect(assigns(:events)).to eq([@past_event, @event, @future_event])

          m2.attendance = 'Declined'
          m2.save
          m3.attendance = 'Not Yet Invited'
          m3.save

          get :my_events

          expect(assigns(:events)).to eq([@past_event])
        end
      end

    end

    describe '#past' do
      it 'responds with success code' do
        get :past

        expect(response).to be_successful
      end

      it 'renders :index' do
        get :past

        expect(response).to render_template(:index)
      end

      it 'assigns @events only with events from the past' do
        get :past

        expect(assigns(:events)).to match_array([@past_event])
      end

      context 'with user roles' do
        let(:person) { build(:person) }
        let(:user) { build(:user, person: person, location: 'FOO') }

        before do
          allow(request.env['warden']).to receive(:authenticate!).and_return(user)
          allow(controller).to receive(:current_user).and_return(user)

          @org_loc = @past_event.location
          @past_event.location = user.location
          @past_event.save

          @org_start = @event.start_date
          @org_end = @event.end_date
          @event.start_date = @past_event.start_date - 1.week
          @event.end_date = @past_event.end_date - 1.week
          @event.save
        end

        after do
          @past_event.location = @org_loc
          @past_event.save

          @event.start_date = @org_start
          @event.end_date = @org_end
          @event.save
        end

        it "members: @events includes all past events" do
          user.member!

          get :past

          expect(assigns(:events)).to eq([@past_event, @event])
        end

        it "staff: @events includes all past events" do
          user.staff!

          get :past

          expect(assigns(:events)).to eq([@past_event, @event])
        end

        it "admin: @events includes all past events" do
          user.admin!

          get :past

          expect(assigns(:events)).to eq([@past_event, @event])
        end

        it "super_admin: @events includes all past events" do
          user.super_admin!

          get :past

          expect(assigns(:events)).to eq([@past_event, @event])
        end
      end
    end

    describe '#future' do
      it 'responds with success code' do
        get :future

        expect(response).to be_successful
      end

      it 'renders :index' do
        get :future

        expect(response).to render_template(:index)
      end

      it 'assigns @events only with the current event and future events' do
        get :future

        expect(assigns(:events)).to match_array([@event, @future_event])
      end

      context 'with user roles' do
        let(:person) { build(:person) }
        let(:user) { build(:user, person: person, location: 'BAR') }

        before do
          allow(request.env['warden']).to receive(:authenticate!).and_return(user)
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "members: @events includes all future events" do
          user.member!

          get :future

          expect(assigns(:events)).to match_array([@event, @future_event])
        end

        it "staff: @events includes all future events" do
          user.member!

          get :future

          expect(assigns(:events)).to match_array([@event, @future_event])
        end

        it "admin: @events includes all future events" do
          user.admin!

          get :future

          expect(assigns(:events)).to match_array([@event, @future_event])
        end

        it "super_admin: @events includes all future events" do
          user.super_admin!

          get :future

          expect(assigns(:events)).to match_array([@event, @future_event])
        end
      end
    end

    describe '#year' do
      let(:year) { Date.today.strftime('%Y') }

      it 'responds with success code' do
        get :year, params: { year: year }

        expect(response).to be_successful
      end

      it 'renders :index' do
        get :year, params: { year: year }

        expect(response).to render_template(:index)
      end

      it 'assigns @events to events of [year]' do
        year = @future_event.start_date.strftime('%Y')
        expect(@event.start_date.strftime('%Y')).not_to eq(year)
        expect(@past_event.start_date.strftime('%Y')).not_to eq(year)

        get :year, params: { year: year }

        expect(assigns(:events)).to eq([@future_event])
      end

      it 'redirects to events_path given an invalid year' do
        %w[2015foo bar2013 wookie 1 12 123].each do |badyear|
          get :year, params: { year: badyear }

          expect(response).to redirect_to(events_path)
        end
      end
    end

    describe '#location' do
      Setting.Locations.keys.each do |loc|
        context ":#{loc}" do
          let(:location) { loc }

          it 'responds with success code' do
            get :location, params: { location: location }

            expect(response).to be_successful
          end

          it 'renders :index' do
            get :location, params: { location: location }

            expect(response).to render_template(:index)
          end

          it %(assigns @events to events at #{loc} location) do
            org_loc = @future_event.location
            @future_event.location = 'ELSE'
            @future_event.save

            get :location, params: { location: location }

            expect(assigns(:events)).to eq([@past_event, @event])

            @future_event.location = org_loc
            @future_event.save
          end
        end
      end

      it 'given an invalid location, it uses the first configured location' do
        legit_location = Setting.Locations.keys.first
        expect(@past_event.location).to eq(legit_location)
        expect(@event.location).to eq(legit_location)
        expect(@future_event.location).to eq(legit_location)

        %w[random-place another-place somewhere].each do |place|
          get :location, params: { location: place }

          expect(assigns(:events)).to eq([@past_event, @event, @future_event])
          expect(response).to render_template(:index)
        end
      end
    end

    describe '#kind' do
      Setting.Site['event_types'].each do |type|
        context ":#{type}" do
          let(:kind) { type.parameterize }

          it 'responds with success code' do
            get :kind, params: { kind: kind }

            expect(response).to be_successful
          end

          it 'renders :index' do
            get :kind, params: { kind: kind }

            expect(response).to render_template(:index)
          end

          it %(assigns @events to events of type #{type}) do
            org_type = @event.event_type
            @event.event_type = type
            @event.save

            another_type = type
            until another_type != type
              another_type = Setting.Site['event_types'].sample
            end

            org_type2 = @future_event.event_type
            @future_event.event_type = another_type
            @future_event.save
            org_type3 = @past_event.event_type
            @past_event.event_type = another_type
            @past_event.save

            get :kind, params: { kind: kind }

            expect(assigns(:events)).to eq([@event])

            @event.event_type = org_type
            @event.save
            @future_event.event_type = org_type2
            @future_event.save
            @past_event.event_type = org_type3
            @past_event.save
          end
        end
      end

      it 'given an invalid event type, it assumes the first configured type' do
        legit_type = Setting.Site['event_types'].first
        expect(@past_event.event_type).to eq(legit_type)
        expect(@event.event_type).to eq(legit_type)
        expect(@future_event.event_type).to eq(legit_type)

        %w(lynch-mob circus funeral).each do |invalid_type|

          get :kind, params: { kind: invalid_type }

          expect(assigns(:events)).to eq([@past_event, @event, @future_event])
          expect(response).to render_template(:index)
        end
      end
    end
  end
