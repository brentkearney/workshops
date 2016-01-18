# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EventsController, type: :controller do

  let(:valid_attributes) { FactoryGirl.attributes_for(:event) }
  let(:invalid_attributes) { FactoryGirl.attributes_for(:event, code: 666)}
  let(:all_events) { 10.times { FactoryGirl.create(:event) } }

  before do
    Event.destroy_all
  end

  describe "GET #index" do
    context 'as a logged in user' do
      before(:each) do
        all_events
        authenticate_for_controllers # sets @user, @person, @event, @membership
        get :index
        expect(response.status).to eq(200)
        expect(response).to render_template(:index)
      end

      it "assigns the user's events to @events" do
        expect(Event.all.size).to eq(11)
        expect(assigns(:events)).to eq([@event])
      end

      it "assigns a page heading" do
        expect(assigns(:heading)).to eq('Your Events')
      end
    end
  end

  describe 'Get #all' do
    before do
      authenticate_for_controllers
      get :all
      expect(response.status).to eq(200)
      expect(response).to render_template(:index)
    end

    it 'assigns all events to @events' do
      expect(assigns(:events)).to eq([@event])
    end

  end

  describe "GET #show" do
    it "assigns the requested event as @event" do
      authenticate_for_controllers
      get :show, {:id => @event.to_param}
      expect(response.status).to eq(200)
      expect(response).to render_template(:show)
      expect(assigns(:event)).to eq(@event)
    end
  end

  describe "GET #new" do
    it "assigns a new event as @event" do
      authenticate_for_controllers
      @user.admin!
      get :new
      expect(assigns(:event)).to be_a_new(Event)
    end
  end

  describe "GET #edit" do
    it "assigns the requested event as @event" do
      authenticate_for_controllers
      @user.admin!
      get :edit, {:id => @event.to_param}
      expect(assigns(:event)).to eq(@event)
    end
  end

  describe "POST #create" do
    before do
      authenticate_for_controllers
      @user.admin!
    end

    context "with valid params" do
      it "creates a new Event" do
        expect {
          post :create, {:event => valid_attributes}
        }.to change(Event, :count).by(1)
      end

      it "assigns a newly created event as @event" do
        post :create, {:event => valid_attributes}
        expect(assigns(:event)).to be_a(Event)
        expect(assigns(:event)).to be_persisted
      end

      it "redirects to the created event" do
        post :create, {:event => valid_attributes}
        expect(response).to redirect_to(Event.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved event as @event" do
        post :create, {:event => invalid_attributes}
        expect(assigns(:event)).to be_a_new(Event)
      end

      it "re-renders the 'new' template" do
        post :create, {:event => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before do
      authenticate_for_controllers
      @user.admin!
    end

    context "with valid params" do
      let(:new_attributes) { FactoryGirl.attributes_for(:event, start_date: '2016-01-10', end_date: '2016-01-15') }

      it "updates the requested event" do
        event = Event.create! valid_attributes
        put :update, {:id => event.to_param, :event => new_attributes}
        event.reload
        expect(event.start_date.to_s).to eq('2016-01-10')
        expect(event.end_date.to_s).to eq('2016-01-15')
      end

      it "assigns the requested event as @event" do
        event = Event.create! valid_attributes
        put :update, {:id => event.to_param, :event => valid_attributes}
        expect(assigns(:event)).to eq(event)
      end

      it "redirects to the event" do
        event = Event.create! valid_attributes
        put :update, {:id => event.to_param, :event => valid_attributes}
        expect(response).to redirect_to(event)
      end
    end

    context "with invalid params" do
      it "assigns the event as @event" do
        event = Event.create! valid_attributes
        put :update, {:id => event.to_param, :event => invalid_attributes}
        expect(assigns(:event)).to eq(event)
      end

      it "re-renders the 'edit' template" do
        event = Event.create! valid_attributes
        put :update, {:id => event.to_param, :event => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      authenticate_for_controllers
      @user.admin!
    end

    it "destroys the requested event" do
      event = Event.create! valid_attributes
      expect {
        delete :destroy, {:id => event.to_param}
      }.to change(Event, :count).by(-1)
    end

    it "redirects to the events list" do
      event = Event.create! valid_attributes
      delete :destroy, {:id => event.to_param}
      expect(response).to redirect_to(events_url)
    end
  end

end
