# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# API for updating Lecture records
class Api::V1::LecturesController < Api::V1::BaseController
  before_action :authenticated?, :find_lecture
  respond_to :json

  # PATCH/PUT /api/v1/lectures/1.json
  def update
    @json['lecture']['updated_by'] = 'Automated Video System'
    @lecture.assign_attributes(@json['lecture'])

    respond_to do |format|
      if @lecture.save
        format.json { head :created }
      else
        format.json do
          render json: @lecture.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # GET /api/v1/todays_lectures/date.json
  def todays_lectures
    lectures = Lecture.where("start_time >= ? AND end_time <= ? AND room = '#{@room}'",
                  DateTime.current.beginning_of_day, DateTime.current.end_of_day)
                  .order(:start_time)
    schedules = Schedule.where(lecture_id: lectures.pluck(:id))

    data = []
    lectures.each do |lecture|
      schedule = schedules.select {|s| s.lecture_id == lecture.id}.first
      start_time = schedule.nil? ? '' : schedule.start_time
      end_time = schedule.nil? ? '' : schedule.end_time
      # lecture time (updated by recording system) may differ from its sheduled time
      scheduled_for = { start_time: start_time, end_time: end_time }
      data << { lecture: lecture, scheduled_for: scheduled_for }
    end

    respond_to do |format|
      format.json do
        render json: data.to_json
      end
    end
  end

  def method_missing(method_name, *arguments, &block)
    Rails.logger.debug "\n\nAPI received unimplemented method: #{method_name}, args: #{arguments.pretty_inspect}\n\n"
    go_away
    super
  end

  def respond_to_missing?
    super
  end

  private

  def find_lecture
    return if request.request_method == 'GET'
    @lecture = nil
    go_away && return unless valid_parameters?

    begin
      event = Event.find(@json['event_id'])
      lecture = Lecture.find(@json['lecture_id'])
    rescue ActiveRecord::RecordNotFound
      go_away && return
    end
    if confirm_legacy_db_consistency(event, lecture)
      @lecture = lecture
    end
  end

  # safety check due to legacy_db SNAFU
  def confirm_legacy_db_consistency(event, lecture)
    event && lecture && lecture.event_id == event.id || go_away && false
  end

  def authenticated?
    @authenticated || unauthorized
  end

  def go_away
    head :bad_request
  end

  def valid_parameters?
    @json['event_id'] && @json['lecture_id'] && @json.key?('lecture') &&
      @json['lecture'].is_a?(Hash) && !@json['lecture'].empty?
  end
end
