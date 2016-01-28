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
    @events = current_user.person.events

    render :index
  end

  # GET /events/scope/future || past || year || location
  def scope
    scope = event_scope
    @heading = scope[:title]
    @events = Event.send(scope[:method], scope[:args])

    render :index
  end

  # GET /events/kind/
  def kind
    @heading = event_kind.pluralize
    @events = Event.kind(event_kind)

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

    def event_scope
      data = {title: '', method: '', args: ''}

      case params[:scope]
        when 'year'
          year = params[:format]

          if year =~ /\d{4}/
            data[:title] = year
            data[:method] = 'year'
            data[:args] = year
          else
            redirect_to events_path
          end

        when 'location'
          location = params[:format]
          location = Global.location.first unless Global.location.key?(location)
          
          data[:title] = location
          data[:method] = 'location'
          data[:args] = location

        when 'past', 'future'
          data[:title] = params[:scope]
          data[:method] = params[:scope]

        else
          redirect_to events_path
        end

      data[:title] = data[:title].capitalize + ' Events'
      data
    end

    def event_kind
      if params[:kind] == 'research-in-teams'
        return 'Research in Teams'
      else
        kind = params[:kind].titleize
        if kind.singularize.in? Global.event.types
          kind
        else
          '5 Day Workshops'
        end
      end
    end
end
