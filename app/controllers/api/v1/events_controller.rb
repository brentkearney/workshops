# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# API for adding Event records
class Api::V1::EventsController < Api::V1::BaseController
  before_filter :authenticated?
  respond_to :json

  # POST /api/v1/events/1.json
  def create
    go_away && return unless valid_parameters? && event_does_not_exist?
    event = Event.new
    event.assign_attributes(@json['event'])

    respond_to do |format|
      if event.save
        format.json { render nothing: true, status: :created }
      else
        format.json { render json: event.errors, status: :unprocessable_entity }
      end
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
    render nothing: true, status: :bad_request
  end

  def valid_parameters?
    @json['event_id'] && @json.key?('event') &&
      @json['event'].is_a?(Hash) && !@json['event'].empty? &&
      @json['event_id'] == @json['event']['code']
  end
end
