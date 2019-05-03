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
    @lecture.from_api = true

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

  # GET /api/v1/lecture/id.json
  def lecture_data
    data = {}
    lecture = Lecture.find_by_id(@lecture_id) || Lecture.find_by_legacy_id(@lecture_id)
    unless lecture.blank?
      person = {
        salutation: lecture.person.salutation,
        firstname: lecture.person.firstname,
        lastname: lecture.person.lastname,
        affiliation: lecture.person.affiliation,
        email: lecture.person.email,
        legacy_id: lecture.person.legacy_id
      }
      event = {
        code: lecture.event.code,
        name: lecture.event.name,
        event_type: lecture.event.event_type,
        start_date: lecture.event.start_date,
        end_date: lecture.event.end_date,
        location: lecture.event.location
      }
      data = { lecture: lecture.attributes, person: person, event: event }
    end

    respond_to do |format|
      format.json do
        render json: data.to_json
      end
    end
  end

  # GET /api/v1/lectures_on_date/room/date.json
  def lectures_on
    lectures = Lecture.where(start_time: @date.beginning_of_day..@date.end_of_day)
                       .where(room: @room).order(:start_time)
    schedules = Schedule.where(lecture_id: lectures.pluck(:id))

    data = []
    lectures.each do |lecture|
      schedule = schedules.select {|s| s.lecture_id == lecture.id}.first
      start_time = schedule.nil? ? '' : schedule.start_time
      end_time = schedule.nil? ? '' : schedule.end_time
      # lecture time (updated by recording system) may differ from its sheduled time
      scheduled_for = { start_time: start_time, end_time: end_time }

      extras = {
        event_code: lecture.event.code,
        firstname: lecture.person.firstname,
        lastname: lecture.person.lastname,
        affil: lecture.person.affiliation
      }
      lecture_attribs = lecture.attributes.merge(extras)

      data << { lecture: lecture_attribs, scheduled_for: scheduled_for }
    end

    respond_to do |format|
      format.json do
        render json: data.to_json
      end
    end
  end

  def method_missing(method_name, *arguments, &block)
    go_away
    super
  end

  def respond_to_missing?(method_name, *arguments)
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
