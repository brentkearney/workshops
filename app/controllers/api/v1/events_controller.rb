# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# API for adding Event records
class Api::V1::EventsController < Api::V1::BaseController
  before_action :authenticated?
  respond_to :json

  # POST /api/v1/events/1.json
  def create
    go_away && return unless valid_create_parameters? && event_does_not_exist?
    event = Event.new
    event.assign_attributes(@json['event'])

    if event.max_participants.blank? || event.max_participants == 0
      event.max_participants = GetSetting.max_participants(event.location)
    end
    event.max_observers = GetSetting.max_observers(event.location)

    respond_to do |format|
      if event.save
        format.json { head :created }
      else
        format.json { render json: event.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /api/v1/events/sync/1.json
  def sync
    go_away && return unless valid_event_id?
    event = Event.find_by_code(@json['event_id'])
    go_away && return if event.nil?

    SyncEventMembersJob.perform_later(event.id)

    respond_to do |format|
      format.json { head :success }
    end
  end

  def method_missing(method_name, *arguments, &block)
    go_away
    super
  end

  def respond_to_missing?
    super
  end

  private

  def event_does_not_exist?
    Event.find_by_code(@json['event_id']).nil?
  end

  def authenticated?
    @authenticated || unauthorized
  end

  def go_away
    head :bad_request
  end

  def valid_event_id?
    return false if @json['event_id'].nil?
    @json['event_id'] =~ /#{GetSetting.code_pattern}/
  end

  def valid_create_parameters?
    valid_event_id? && @json.key?('event') &&
      @json['event'].is_a?(Hash) && !@json['event'].empty? &&
      @json['event_id'] == @json['event']['code']
  end
end
