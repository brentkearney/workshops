# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class EventsController < ApplicationController
  before_action :set_event, :set_time_zone, :set_attendance,
                only: [:show, :edit, :update, :destroy]
  before_action :set_params, only: [:past, :future, :year, :location, :kind]
  before_action :authenticate_user!,
                only: [:my_events, :org_events, :new, :edit, :create, :update,
                  :destroy]
  after_action :verify_policy_scoped, only: [:index, :past, :future, :kind]

  include EventsHelper

  # GET /events
  # GET /events.json
  def index
    @events = policy_scope(Event).reverse_order
  end

  # GET /events/my_events
  def my_events
    @events = current_user.person.events.order(:start_date)
    render :index unless performed?
  end

  # GET /events/org_events
  def org_events
    @events = current_user.person.memberships
                          .select(&:organizer?).collect(&:event)

    render :index unless performed?
  end

  # GET /events/past(/location/:location)
  # GET /events/past.json(/location/:location).json
  def past
    @tense = 'Past'
    @events = policy_scope(Event).past.reverse_order.to_ary
    remove_locations
    render :index unless performed?
  end

  # GET /events/future(/location/:location)
  # GET /events/future(/location/:location).json
  def future
    @tense = 'Future'
    @events = policy_scope(Event).future
    remove_locations
    render :index unless performed?
  end

  # GET /events/year/:year
  # GET /events/year/:year.json
  def year
    if @year.match?(/^\d{4}$/)
      @events = policy_scope(Event).year(@year)
      remove_locations
      remove_kinds
      render :index unless performed?
    else
      redirect_to events_path
    end
  end

  # GET /events/location/:location
  # GET /events/location/:location.json
  def location
    @location = allowed_params[:location]
    unless Setting.Locations.keys.include?(@location)
      @location = Setting.Locations.keys.first
    end
    @events = Event.location(@location).order(:start_date).limit(100)
    render :index unless performed?
  end

  # GET /events/kind/:kind
  def kind
    kind = allowed_params[:kind].titleize
    if kind == 'Research In Teams'
      kind = 'Research in Teams'
    else
      unless Setting.Site['event_types'].include?(kind.singularize)
        kind = Setting.Site['event_types'].first
      end
    end

    if @year.blank?
      @events = policy_scope(Event).future.kind(kind).reverse
    else
      @events = policy_scope(Event).year(@year).kind(kind)
    end

    render :index unless performed?
  end

  # GET /events/1
  # GET /events/1.json
  def show
    if @event
      authorize(@event) # only staff see template events
      @organizers = []
      @members = []
      @event.memberships.order('role asc')
            .includes(:person).order('people.lastname').each do |member|
        if member.role.match?(/Organizer/)
          @organizers << @event.member_info(member.person)
        end
        if member.attendance == 'Confirmed'
          @members << @event.member_info(member.person)
        end
      end
      SyncEventMembersJob.perform_later(@event.id) if policy(@event).sync?
    else
      redirect_to root_path, error: 'No valid event specified.'
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
    @editable_fields = policy(@event).may_edit
    @edit_form = current_user.is_admin? ? 'admin_form' : 'member_form'
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    authorize @event

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event,
            notice: "Event #{@event.code} was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors,
            status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    authorize @event

    original_event = @event.dup
    @editable_fields = policy(@event).may_edit
    @edit_form = current_user.is_admin? ? 'admin_form' : 'member_form'
    update_params = event_params.to_h.assert_valid_keys(*@editable_fields)
        .merge(updated_by: current_user.name)

    respond_to do |format|
      if @event.update(update_params)
        notify_staff(event: original_event, params: update_params)
        flash[:notice] = @event.notice
        format.html { redirect_to @event,
            success: "Event #{@event.code} was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors,
            status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    authorize @event
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url,
        success: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def notify_staff(event: original_event, params: update_params)
    if params[:short_name] != event.short_name && event.upcoming?
      EmailNametagUpdateJob.perform_later(event.code, params)
    end

    if params[:description] != event.description ||
        params[:press_release] != event.press_release
      EmailEventUpdateJob.perform_later(event.code, params)
    end
  end

  def event_params
    params.require(:event).permit(:code, :name, :short_name, :start_date,
                                  :end_date, :time_zone, :event_type, :location,
                                  :description, :press_release, :door_code,
                                  :booking_code, :subjects, :cancelled,
                                  :max_participants, :max_observers,
                                  :max_virtual, :updated_by, :event_format)
  end

  def allowed_params
    params.permit(:location, :year, :kind)
  end

  def set_params
    @location = allowed_params[:location]
    @year = allowed_params[:year]
    @kind = allowed_params[:kind]
  end

  def remove_locations
    @events = @events.select {|e| e.location == @location} unless @location.blank?
    @events = @events[0 ... 100]
  end

  def remove_years
    @events = @events.select {|e| e.year == @year } unless @year.blank?
  end

  def remove_kinds
    @events = @events.select {|e| e.event_type == @kind.titleize } unless @kind.blank?
  end
end
