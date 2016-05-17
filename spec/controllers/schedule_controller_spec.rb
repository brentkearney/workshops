# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe ScheduleController, type: :controller do
  before do
    # sets @user, @person, @event, @membership
    authenticate_for_controllers
    build_schedule_template(@event.event_type)

    start_time = (@event.start_date + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min:0 })
    end_time = (@event.start_date + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min:30 })
    @valid_attributes = FactoryGirl.attributes_for(:schedule,
        event_id: @event.id, start_time: start_time, end_time: end_time).merge(new_item: true)

    @invalid_attributes = FactoryGirl.attributes_for(:schedule, event_id: @event.id, name: '', start_time: start_time, end_time: end_time)
    @day = @event.start_date + 1.days
  end

  after do
    Lecture.delete_all
    Schedule.delete_all
  end

  describe "GET #index" do
    context 'as an external user (not-signed in)' do
      before do
        sign_out @user
        expect(@event).not_to be_nil
        expect(@event.schedules).to be_empty
        for hour in 9..16
          start_time = (@event.start_date + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: hour, min:0})
          end_time = (@event.start_date + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: hour, min:30})
          name = "Schedule Item at #{hour}"
          FactoryGirl.create(:schedule, event: @event, start_time: start_time, end_time: end_time, name: name)
        end
        expect(@event.schedules).not_to be_empty
      end

      after do
        @event.schedules.delete_all
        expect(@event.schedules).to be_empty
      end

      it 'if event.publish_schedule is false, redirects to sign-in page' do
        @event.publish_schedule = false
        @event.save

        get :index, { :event_id => @event.id }

        expect(response.status).to eq(302)
        expect(subject).to redirect_to(sign_in_path)
      end

      it 'if event.publish_schedule is true, assigns @schedules' do
        @event.publish_schedule = true
        @event.save

        get :index, { :event_id => @event.id }

        expect(response.status).to eq(200)
        expect(response).to render_template('index')
        expect(assigns(:schedules)).not_to be_empty
      end

    end

    context 'as an organizer' do
      before do
        authenticate_for_controllers
        @membership.role = 'Organizer'
        @membership.save
      end

      it 'assigns @schedules copied from template event upon first visit' do
        @event.schedules.destroy_all
        template = Event.find_by(template: true)
        expect(template.schedules).not_to be_empty

        get :index, { :event_id => @event.id }

        expect(response.status).to eq(200)
        expect(response).to render_template('index')
        expect(assigns(:schedules)).not_to be_empty
      end
    end

    context 'as a participant' do
      before do
        authenticate_for_controllers
        @membership.role = 'Participant'
        @membership.save
        @event.schedules.delete_all
      end

      it 'assigns an empty @schedules upon first visit' do
        expect(@event.schedules).to be_empty
        get :index, { :event_id => @event.id }
        expect(response.status).to eq(200)
        expect(response).to render_template('index')
        expect(assigns(:schedules)).to be_empty
      end
    end



  end


  describe "GET #new/:day" do
    it "assigns a new schedule as @schedule, on :day" do
      @membership.role = 'Organizer'
      @membership.save

      day = @event.start_date + 2.days
      get :new, { :event_id => @event.id, :day => day }
      expect(assigns(:schedule)).to be_a_new(Schedule)
    end
  end

  describe "GET #edit" do
    it "assigns the requested schedule as @schedule and its date as @day" do
      @membership.role = 'Organizer'
      @membership.save

      start_time = (@event.start_date + 1.days).to_time.change({ hour: 9, min:0 })
      end_time = (@event.start_date + 1.days).to_time.change({ hour: 9, min:30 })
      schedule = FactoryGirl.create(:schedule, event: @event, start_time: start_time, end_time: end_time)

      get :edit, { :event_id => @event.id, :id => schedule.to_param }
      expect(assigns(:schedule)).to eq(schedule)
      expect(assigns(:day)).to eq(schedule.day)
    end
  end


  describe "POST #create" do
    before do
      @membership.role = 'Organizer'
      @membership.save
    end

    context "with valid params" do

      it "creates a new Schedule" do
        expect {
          post :create, { :event_id => @event.id, :schedule => @valid_attributes }
        }.to change(Schedule, :count).by(1)
      end

      it "assigns a newly created schedule as @schedule" do
        post :create, { :event_id => @event.id, :schedule => @valid_attributes }
        expect(assigns(:schedule)).to be_a(Schedule)
        expect(assigns(:schedule)).to be_persisted
      end

      it "redirects to the created schedule" do
        post :create, { :event_id => @event.id, :schedule => @valid_attributes }
        day = @event.start_date + 1.days
        expect(response).to redirect_to(event_schedule_day_path(@event, day))
      end
    end

    context "with invalid params" do

      it "assigns a newly created but unsaved schedule as @schedule" do
        post :create, { :event_id => @event.id, :day => @day, :schedule => @invalid_attributes }
        expect(assigns(:schedule)).to be_a(Schedule)
      end

      it "re-renders the 'new' template" do
        post :create, { :event_id => @event.id, :day => @day, :schedule => @invalid_attributes }
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before do
      @membership.role = 'Organizer'
      @membership.save
      @valid_attributes.delete :new_item
    end

    context "with valid params" do
      let(:new_attributes) {
        @valid_attributes.merge(name: 'A new name', location: 'Back of the bus')
      }
      
      before do
        @schedule = Schedule.create! @valid_attributes
      end

      it "updates the schedule" do
        put :update, { event_id: @event.id, id: @schedule.to_param, schedule: new_attributes }
        @schedule.reload

        expect(@schedule.name).to eq('A new name')
        expect(@schedule.location).to eq('Back of the bus')
        expect(@schedule.updated_by).to eq(@user.name)
      end

      it "assigns @schedule" do
        put :update, { event_id: @event.id, id: @schedule.to_param, schedule: @valid_attributes }

        expect(assigns(:schedule)).to eq(@schedule)
      end

      it 'redirects to session[:return_to]' do
        session[:return_to] = event_schedule_edit_path(@event, @schedule)

        put :update, { event_id: @event.id, id: @schedule.to_param, schedule: @valid_attributes }

        expect(response).to redirect_to(event_schedule_edit_path(@event, @schedule))
      end

      it 'redirects to the schedule index if session[:return_to] = nil' do
        session[:return_to] = nil

        put :update, { event_id: @event.id, id: @schedule.to_param, schedule: @valid_attributes }

        expect(response).to redirect_to(event_schedule_index_path(@event))
      end

      it 'updates similar schedule items if params[:change_similar]' do
        other_item = create(:schedule, event: @event, name: @schedule.name,
                            start_time: @schedule.start_time + 1.days,
                            end_time: @schedule.end_time + 1.days)
        new_start = @valid_attributes[:start_time].change({ hour: 11, min:0 })
        new_end = @valid_attributes[:end_time].change({ hour: 11, min:30 })
        attributes = @valid_attributes.merge(start_time: new_start, end_time: new_end)

        put :update, { event_id: @event.id, id: @schedule.to_param, change_similar: true, schedule: attributes }

        other_item.reload
        @schedule.reload
        expect(other_item.start_time).to eq(@schedule.start_time + 1.days)
      end

      it 'invokes StaffMailer if schedule.staff_item and event.is_current?' do
        @event.start_date = Date.today - 1.day
        @event.end_date = Date.today + 4.days
        @event.save
        schedule = create(:schedule, name: 'New item', event: @event, staff_item: true, start_time: Time.now, end_time: Time.now + 1.hour)
        attributes = schedule.attributes.merge(name: 'Updated item', start_time: Time.now + 1.hour, end_time: Time.now + 2.hours)

        mailer = double('mailer')
        mailer.tap do |mail|
          allow(mailer).to receive(:deliver_now).and_return(true)
          allow(StaffMailer).to receive(:schedule_change).and_return(mailer)
        end

        put :update, { event_id: @event.id, id: schedule.to_param, schedule: attributes }

        expect(StaffMailer).to have_received(:schedule_change)
      end
    end

    context "with invalid params" do
      it "assigns the schedule as @schedule" do
        schedule = Schedule.create! @valid_attributes
        put :update, { :event_id => @event.id, :id => schedule.to_param, :schedule => @invalid_attributes }
        expect(assigns(:schedule)).to eq(schedule)
      end

      it "re-renders the 'edit' template" do
        schedule = Schedule.create! @valid_attributes
        put :update, { :event_id => @event.id, :id => schedule.to_param, :schedule => @invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @membership.role = 'Organizer'
      @membership.save
      @valid_attributes.delete :new_item
    end

    it 'invokes StaffMailer if schedule.staff_item and event.is_current?' do
      @event.start_date = Date.today - 1.day
      @event.end_date = Date.today + 4.days
      @event.save
      schedule = create(:schedule, name: 'New item', event: @event, staff_item: true, start_time: Time.now, end_time: Time.now + 1.hour)
      attributes = schedule.attributes.merge(name: 'Updated item', start_time: Time.now + 1.hour, end_time: Time.now + 2.hours)

      mailer = double('mailer')
      mailer.tap do |mail|
        allow(mailer).to receive(:deliver_now).and_return(true)
        allow(StaffMailer).to receive(:schedule_change).and_return(mailer)
      end

      delete :destroy, { event_id: @event.id, id: schedule.to_param }

      expect(StaffMailer).to have_received(:schedule_change)
    end

    it "destroys the requested schedule" do
      schedule = Schedule.create! @valid_attributes
      expect {
        delete :destroy, { event_id: @event.id, id: schedule.to_param }
      }.to change(Schedule, :count).by(-1)
    end

    it "destroys the associated lecture item" do
      schedule = Schedule.create! @valid_attributes
      lecture = FactoryGirl.create(:lecture, event: @event, person: @person,
                                   start_time: schedule.start_time,
                                   end_time: schedule.end_time)
      schedule.lecture = lecture
      schedule.save

      expect {
        delete :destroy, { event_id: @event.id, id: schedule.to_param }
      }.to change(Lecture, :count).by(-1)
    end

    it "redirects to the schedule list" do
      schedule = Schedule.create! @valid_attributes
      delete :destroy, { event_id: @event.id, id: schedule.to_param }
      expect(response).to redirect_to(event_schedule_index_path(@event))
    end
  end

=begin
  # Show isn't implemented yet
  describe "GET #show" do
    it "assigns the requested schedule as @schedule" do
      start_time = (@event.start_date + 1.days).to_time.change({ hour: 9, min:0 })
      end_time = (@event.start_date + 1.days).to_time.change({ hour: 9, min:30 })
      schedule = FactoryGirl.create(:schedule, event: @event, start_time: start_time, end_time: end_time)

      get :show, {:event_id => @event.id, :id => schedule.to_param}
      expect(assigns(:schedule)).to eq(schedule)
    end
  end
=end

end

def build_schedule_template(event_type)
  template_event = FactoryGirl.create(:event, event_type: event_type, template: true, name: 'Schedule Template Event')
  #schedules = 5.times { FactoryGirl.create(:schedule, event: template_event, name: 'Schedule template item') }
  for hour in 9..16
    start_time = (template_event.start_date + 1.days).to_time.in_time_zone(template_event.time_zone).change({ hour: hour, min:0})
    end_time = (template_event.start_date + 1.days).to_time.in_time_zone(template_event.time_zone).change({ hour: hour, min:30})
    name = "Template Item at #{hour}"
    item = FactoryGirl.create(:schedule, event: template_event, start_time: start_time, end_time: end_time, name: name)
  end
end