# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class EventsController < ApplicationController
  before_action :set_event, :set_attendance
  before_filter :authenticate_user!, :only => [:my_events, :new, :edit, :create, :update, :destroy]

  # GET /events
  # GET /events.json
  def index
    @events = policy_scope(Event)
    @heading = 'All Events'
  end

  # Get /events/mine
  def my_events
    @heading = 'My Events'
    @events = current_user.person.events.order(:start_date)
    render :index
  end

  # GET /events/past
  # GET /events/past.json
  def past
    @heading = 'Past Events'
    @events = Event.past
    render :index
  end

  # GET /events/future
  # GET /events/future.json
  def future
    @heading = 'Future Events'
    @events = Event.future
    render :index
  end

  # GET /events/year/:year
  # GET /events/year/:year.json
  def year
    year = params[:year]
    if year =~ /^\d{4}$/
      @heading = "#{year} Events"
      @events = Event.year(year)
      render :index
    else
      redirect_to events_path
    end
  end

  # GET /events/location/:location
  # GET /events/location/:location.json
  def location
    location = params[:location]
    location = Global.location.first unless Global.location.all.include?(location)

    @heading = "Events at #{location}"
    @events = Event.location(location)
    render :index
  end

  # GET /events/kind/:kind
  def kind
    kind = params[:kind]
    # pluralizing Research in Teams makes it invalid
    unless kind == 'Research in Teams' || Global.event.types.include?(kind.singularize)
      kind = Global.event.types.first
    end

    @heading = kind.pluralize
    @events = Event.kind(kind)
    render :index
  end

  # GET /events/1
  # GET /events/1.json
  def show
    if @event
      authorize(@event) # only staff see template events
      SyncEventMembersJob.perform_later(@event) if policy(@event).sync?
    end
  end

  # GET /events/new
  def new
    @event = Event.new
    authorize @event
  end

  # GET /events/1/edit
  def edit
    authorize @event
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    authorize @event

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    authorize @event
    respond_to do |format|
      if @event.update(event_params.merge(:updated_by => current_user.name))
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    authorize @event
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def event_params
      params.require(:event).permit(:code, :name, :short_name, :start_date, :end_date, :time_zone, :event_type, :location, :description, :press_release, :max_participants, :door_code, :booking_code, :updated_by)
    end
end
