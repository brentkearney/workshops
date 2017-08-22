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

    start_time = (@event.start_date + 1.days)
                 .to_time.in_time_zone(@event.time_zone)
                 .change(hour: 9, min: 0)
    end_time = (@event.start_date + 1.days)
               .to_time.in_time_zone(@event.time_zone)
               .change(hour: 9, min: 30)
    @valid_attributes = attributes_for(:schedule, event_id: @event.id,
                                                  start_time: start_time,
                                                  end_time: end_time)
                        .merge(new_item: true)

    @invalid_attributes = attributes_for(:schedule, event_id: @event.id,
                                                    name: '',
                                                    start_time: start_time,
                                                    end_time: end_time)
    @day = @event.start_date + 1.days
  end

  after do
    Lecture.delete_all
    Schedule.delete_all
  end

  describe 'GET #index' do
    context 'as an external user (not-signed in)' do
      before do
        sign_out @user
        (9..16).each do |hour|
          start_time = (@event.start_date + 1.days)
                       .to_time.in_time_zone(@event.time_zone)
                       .change(hour: hour, min: 0)
          end_time = (@event.start_date + 1.days)
                     .to_time.in_time_zone(@event.time_zone)
                     .change(hour: hour, min: 30)
          name = "Schedule Item at #{hour}"
          create(:schedule, event: @event, start_time: start_time,
                            end_time: end_time, name: name)
        end
      end

      after do
        @event.schedules.delete_all
      end

      it 'if event.publish_schedule is false, redirects to sign-in page' do
        @event.publish_schedule = false
        @event.save

        get :index, event_id: @event.id

        expect(response.status).to eq(302)
        expect(subject).to redirect_to(sign_in_path)
      end

      it 'if event.publish_schedule is true, it assigns @schedules' do
        expect(@event.schedules).not_to be_empty
        @event.publish_schedule = true
        @event.save

        get :index, event_id: @event.id

        expect(@event.schedules).not_to be_empty
        expect(response.status).to eq(200)
        expect(response).to render_template('index')
        expect(assigns(:schedules)).not_to be_empty
      end

      it 'if event.publish_schedule is true, but @schedules is empty,
          it redirects to sign-in' do
        @event.publish_schedule = true
        @event.schedules.delete_all
        @event.save

        get :index, format: :html, event_id: @event.id

        expect(response.status).to eq(302)
        expect(subject).to redirect_to(sign_in_path)
      end
    end

    context 'as an organizer' do
      before do
        authenticate_for_controllers
        @membership.role = 'Organizer'
        @membership.save
        @event.schedules.destroy_all
        @template_event = Event.find_by(template: true)
        expect(@template_event.schedules).not_to be_empty
      end

      it 'assigns @schedules copied from template event upon first visit' do
        get :index, event_id: @event.id

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
        get :index, event_id: @event.id
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
      get :new, event_id: @event.id, day: day
      expect(assigns(:schedule)).to be_a_new(Schedule)
    end
  end

  describe "GET #edit" do
    it "assigns the requested schedule as @schedule and its date as @day" do
      @membership.role = 'Organizer'
      @membership.save

      start_time = (@event.start_date + 1.days).to_time.change(hour: 9, min: 0)
      end_time = (@event.start_date + 1.days).to_time.change(hour: 9, min: 30)
      schedule = create(:schedule, event: @event,
                                   start_time: start_time, end_time: end_time)

      get :edit, event_id: @event.id, id: schedule.to_param
      expect(assigns(:schedule)).to eq(schedule)
      expect(assigns(:day)).to eq(schedule.day)
    end
  end


  describe 'POST #create' do
    before do
      @membership.role = 'Organizer'
      @membership.save
    end

    context 'with valid params' do
      it 'creates a new Schedule' do
        expect {
          post :create, event_id: @event.id, schedule: @valid_attributes
        }.to change(Schedule, :count).by(1)
      end

      it 'assigns a newly created schedule as @schedule' do
        post :create, event_id: @event.id, schedule: @valid_attributes
        expect(assigns(:schedule)).to be_a(Schedule)
        expect(assigns(:schedule)).to be_persisted
      end

      it 'redirects to the created schedule' do
        post :create, event_id: @event.id, schedule: @valid_attributes
        day = @event.start_date + 1.days
        expect(response).to redirect_to(event_schedule_day_path(@event, day))
      end

      it 'notifies staff (for current event)' do
        allow_any_instance_of(Schedule).to receive(:notify_staff?)
          .and_return(true)
        ActionMailer::Base.deliveries.clear

        post :create, event_id: @event.id, schedule: @valid_attributes
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved schedule as @schedule' do
        post :create, event_id: @event.id, day: @day,
                      schedule: @invalid_attributes
        expect(assigns(:schedule)).to be_a(Schedule)
      end

      it "re-renders the 'new' template" do
        post :create, event_id: @event.id, day: @day,
                      schedule: @invalid_attributes
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    before do
      @membership.role = 'Organizer'
      @membership.save
      @valid_attributes.delete :new_item
    end

    context 'with valid params' do
      let(:new_attributes) {
        @valid_attributes.merge(name: 'A new name', location: 'Back of the bus')
      }

      before do
        @user.admin!
        @schedule = Schedule.create! @valid_attributes
      end

      it 'updates the schedule' do
        put :update, event_id: @event.id, id: @schedule.to_param,
                     schedule: new_attributes
        @schedule.reload

        expect(@schedule.name).to eq('A new name')
        expect(@schedule.location).to eq('Back of the bus')
        expect(@schedule.updated_by).to eq(@user.name)
      end

      it "assigns @schedule" do
        put :update, event_id: @event.id, id: @schedule.to_param,
                     schedule: @valid_attributes

        expect(assigns(:schedule)).to eq(@schedule)
      end

      it 'redirects to session[:return_to]' do
        session[:return_to] = event_schedule_edit_path(@event, @schedule)

        put :update, event_id: @event.id, id: @schedule.to_param,
                     schedule: @valid_attributes

        redirect_path = event_schedule_edit_path(@event, @schedule)
        expect(response).to redirect_to(redirect_path)
      end

      it 'redirects to the schedule index if session[:return_to] = nil' do
        session[:return_to] = nil

        put :update, event_id: @event.id, id: @schedule.to_param,
                     schedule: @valid_attributes

        expect(response).to redirect_to(event_schedule_index_path(@event))
      end

      it 'notifies staff (for current events)' do
        allow_any_instance_of(Schedule).to receive(:notify_staff?)
          .and_return(true)
        ActionMailer::Base.deliveries.clear

        put :update, event_id: @event.id, id: @schedule.to_param,
                             schedule: @valid_attributes

        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it 'updates similar schedule items if params[:change_similar]' do
        other = create(:schedule, event: @event, name: @schedule.name,
                                  start_time: @schedule.start_time + 1.days,
                                  end_time: @schedule.end_time + 1.days)
        new_start = @valid_attributes[:start_time].change(hour: 11, min: 0)
        new_end = @valid_attributes[:end_time].change(hour: 11, min: 30)
        attributes = @valid_attributes.merge(start_time: new_start,
                                             end_time: new_end)

        put :update, event_id: @event.id, id: @schedule.to_param,
                     change_similar: true, schedule: attributes

        other.reload
        @schedule.reload
        expect(other.start_time).to eq(@schedule.start_time + 1.days)
      end
    end

    context 'with invalid params' do
      before do
        @user.admin!
      end

      it 'assigns the schedule as @schedule' do
        schedule = Schedule.create! @valid_attributes
        put :update, event_id: @event.id, id: schedule.to_param,
                     schedule: @invalid_attributes
        expect(assigns(:schedule)).to eq(schedule)
      end

      it "re-renders the 'edit' template" do
        schedule = Schedule.create! @valid_attributes
        put :update, event_id: @event.id, id: schedule.to_param,
                     schedule: @invalid_attributes
        expect(response).to render_template('edit')
      end
    end

    context 'for staff items' do
      before do
        @user.member!
        @s_event = create(:event, future: true)
        @membership = create(:membership, role: 'Organizer', event: @s_event,
          person: @person)
        @s_schedule = create(:schedule, staff_item: true, event: @s_event)
        @lock_time = Setting.Site['lock_staff_schedule'].to_duration
      end

      context 'as an organizer outside of locked time' do
        it 'updates the schedule' do
          put :update, event_id: @s_event.id, id: @s_schedule.to_param,
                       schedule: @s_schedule.attributes.merge('name' => 'Yes')
          @s_schedule.reload

          expect(@s_schedule.name).to eq('Yes')
        end

        it 'preserves the staff_item attribute value' do
          expect(@s_schedule.staff_item).to be(true)
          put :update, event_id: @s_event.id, id: @s_schedule.to_param,
                       schedule: @s_schedule.attributes.merge('name' => 'New')
          @s_schedule.reload

          expect(@s_schedule.staff_item).to be(true)

          @s_schedule.staff_item = false
          @s_schedule.save
          put :update, event_id: @s_event.id, id: @s_schedule.to_param,
                       schedule: @s_schedule.attributes.merge('name' => 'Foo')
          @s_schedule.reload

          expect(@s_schedule.staff_item).to be(false)
        end
      end

      context 'as an organizer inside of locked time' do
        it 'does not update the schedule' do
          original_start = @s_event.start_date
          @s_event.start_date = Date.current + @lock_time - 1.day
          @s_event.end_date = @s_event.start_date + 5.days
          @s_event.save
          schedule = create(:schedule, staff_item: true, event: @s_event)
          original_name = schedule.name

          put :update, event_id: @s_event.id, id: schedule.to_param,
                       schedule: schedule.attributes.merge(name: 'No')

          schedule.reload
          expect(schedule.name).to eq(original_name)

          @s_event.start_date = original_start
          @s_event.end_date = original_start + 5.days
          @s_event.save
          schedule.destroy
        end
      end

      context 'as staff' do
        before do
          @membership.destroy!
          @user.staff!
        end

        context 'from different location as event' do
          before do
            @user.location = 'FOO'
            @user.save
            expect(Date.current + @lock_time).to be < @s_event.start_date
          end

          it 'does not update the schedule' do
            @s_schedule.name = 'Before update'
            @s_schedule.save

            put :update, event_id: @s_event.id, id: @s_schedule.to_param,
                         schedule: @s_schedule.attributes.merge(name: 'New')

            @s_schedule.reload
            expect(@s_schedule.name).to eq('Before update')
          end
        end

        context 'from same location as event, within lock time' do
          before do
            @user.location = @s_event.location
            @user.save

            # event within lock time
            @original_start = @s_event.start_date
            @s_event.start_date = Date.current + @lock_time - 1.day
            @s_event.end_date = @s_event.start_date + 5.days
            @s_event.save
          end

          after do
            @s_event.start_date = @original_start
            @s_event.end_date = @s_event.start_date + 5.days
            @s_event.save
          end

          it 'updates the schedule' do
            schedule = create(:schedule, staff_item: true, event: @s_event)

            put :update, event_id: @s_event.id, id: schedule.to_param,
                         schedule: schedule.attributes.merge('name' => 'New')

            expect(Schedule.find(schedule.id).name).to eq('New')
          end

          it 'can change "staff item: true" to false' do
            schedule = create(:schedule, staff_item: true, event: @s_event)

            put :update, event_id: @s_event.id, id: schedule.to_param,
                         schedule: schedule.attributes
                           .merge('staff_item' => false)

            expect(Schedule.find(schedule.id).staff_item).to eq(false)
          end

          it 'can change "staff item: false" to true' do
            schedule = create(:schedule, staff_item: false, event: @s_event)

            put :update, event_id: @s_event.id, id: schedule.to_param,
                         schedule: schedule.attributes
                           .merge('staff_item' => true)

            expect(Schedule.find(schedule.id).staff_item).to eq(true)
          end
        end
      end


      context 'as an admin' do
        before do
          @user.admin!
        end

        context 'from different location as event' do
          before do
            @user.location = 'Elsewhere'
            @user.save
          end

          it 'updates the schedule' do
            schedule = create(:schedule, staff_item: true, event: @s_event)

            put :update, event_id: @s_event.id, id: schedule.to_param,
                         schedule: schedule.attributes.merge('name' => 'New')

            expect(Schedule.find(schedule.id).name).to eq('New')
          end

          it 'can alter the "staff item" attribute' do
            schedule = create(:schedule, staff_item: false, event: @s_event)

            put :update, event_id: @s_event.id, id: schedule.to_param,
                         schedule: schedule.attributes
                           .merge('staff_item' => true)

            expect(Schedule.find(schedule.id).staff_item).to eq(true)
          end
        end

        context 'inside of locked time' do
          before do
            @user.location = @s_event.location
            @user.save

            # event within lock time
            @original_start = @s_event.start_date
            @s_event.start_date = Date.current + @lock_time - 1.day
            @s_event.end_date = @s_event.start_date + 5.days
            @s_event.save
          end

          after do
            @s_event.start_date = @original_start
            @s_event.end_date = @s_event.start_date + 5.days
            @s_event.save
          end

          it 'updates the schedule' do
            schedule = create(:schedule, staff_item: true, event: @s_event)

            put :update, event_id: @s_event.id, id: schedule.to_param,
                         schedule: schedule.attributes.merge('name' => 'New')

            expect(Schedule.find(schedule.id).name).to eq('New')

            schedule.destroy
          end
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      @membership.role = 'Organizer'
      @membership.save
      @valid_attributes.delete :new_item
    end

    it 'notifies staff (for current events)' do
      schedule = Schedule.create! @valid_attributes
      allow_any_instance_of(Schedule).to receive(:notify_staff?)
        .and_return(true)
      ActionMailer::Base.deliveries.clear

      delete :destroy, event_id: @event.id, id: schedule.to_param
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'destroys the requested schedule' do
      schedule = Schedule.create! @valid_attributes
      expect {
        delete :destroy, event_id: @event.id, id: schedule.to_param
      }.to change(Schedule, :count).by(-1)
    end

    it 'destroys the associated lecture item' do
      schedule = Schedule.create! @valid_attributes
      lecture = create(:lecture, event: @event, person: @person,
                                 start_time: schedule.start_time,
                                 end_time: schedule.end_time)
      schedule.lecture = lecture
      schedule.save

      expect {
        delete :destroy, event_id: @event.id, id: schedule.to_param
      }.to change(Lecture, :count).by(-1)
    end

    it 'redirects to the schedule list' do
      schedule = Schedule.create! @valid_attributes
      delete :destroy, event_id: @event.id, id: schedule.to_param
      expect(response).to redirect_to(event_schedule_index_path(@event))
    end
  end
end
