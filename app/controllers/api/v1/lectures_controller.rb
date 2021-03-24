# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# API for updating Lecture records
class Api::V1::LecturesController < Api::V1::BaseController
  before_action :authenticated?, :find_lecture
  respond_to :json
  require 'uri'

  # PATCH/PUT /api/v1/lectures/1.json
  def update
    @json['lecture']['updated_by'] = 'Automated Video System'

    unless @json['lecture']['archiving_license'].blank?
      @json['lecture']['archiving_license'] = URI.decode(@json['lecture']['archiving_license'])
    end
    unless @json['lecture']['hosting_license'].blank?
      @json['lecture']['hosting_license'] = URI.decode(@json['lecture']['hosting_license'])
    end

    @lecture.assign_attributes(@json['lecture'])
    @lecture.from_api = true
    @lecture.local_only = false

    respond_to do |format|
      if @lecture.save
        format.json { head :created }
      else
        Rails.logger.debug "\n\n********************************************\n\n"
        Rails.logger.debug "Error with lecture data:
                            #{@lecture.errors.full_messages.to_json}".squish
        Rails.logger.debug "\n\n********************************************\n\n"
        format.json do
          render json: @lecture.errors.full_messages.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # GET /api/v1/lecture/id.json
  def lecture_data
    data = {}
    # Use legacy_id until legacy system is fully depreciated
    lecture = Lecture.find_by_legacy_id(@lecture_id)
    lecture = Lecture.find_by_id(@lecture_id) if lecture.blank? || Rails.env.test?
    unless lecture.blank?
      person = {
        salutation: lecture.person.salutation,
        firstname: lecture.person.firstname,
        lastname: lecture.person.lastname,
        affiliation: lecture.person.affiliation,
        academic_status: lecture.person.academic_status,
        email: lecture.person.email,
        legacy_id: lecture.person.legacy_id
      }
      event = {
        code: lecture.event.code,
        name: lecture.event.name,
        event_type: lecture.event.event_type,
        start_date: lecture.event.start_date,
        end_date: lecture.event.end_date,
        location: lecture.event.location,
        time_zone: lecture.event.time_zone,
        subjects: lecture.event.subjects
      }
      data = { lecture: lecture.attributes, person: person, event: event }
    end

    respond_to do |format|
      format.json do
        render json: data.to_json
      end
    end
  end

  # GET /api/v1/lectures_on/room/date.json
  def lectures_on
    lectures = GetLectures.on(@date, @room)
    schedules = Schedule.where(lecture_id: lectures.pluck(:id))

    data = []
    lectures.each do |lecture|
      # scheduled time may differ from (actual) lecture time
      schedule = schedules.detect {|s| s.lecture_id == lecture.id}
      start_time = schedule.nil? ? '' : schedule.start_time
      end_time = schedule.nil? ? '' : schedule.end_time
      scheduled_for = { start_time: start_time, end_time: end_time }

      lecture_attribs = compose_data(lecture)
      data << { lecture: lecture_attribs, scheduled_for: scheduled_for }
    end

    respond_to do |format|
      format.json do
        render json: data.to_json
      end
    end
  end


  # GET /api/v1/current/room.json
  def current
    lecture = GetLectures.new(@room).current

    respond_to do |format|
      format.json do
        render json: compose_data(lecture).to_json
      end
    end
  end

  # GET /api/v1/next/room.json
  def next
    lecture = GetLectures.new(@room).next

    respond_to do |format|
      format.json do
        render json: compose_data(lecture).to_json
      end
    end
  end

  # GET /api/v1/last/room.json
  def last
    lecture = GetLectures.new(@room).last

    respond_to do |format|
      format.json do
        render json: compose_data(lecture).to_json
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

  def compose_data(lecture)
    return {} if lecture.blank?
    schedule = Schedule.where(lecture: lecture).first
    start_time = schedule.nil? ? '' : schedule.start_time
    extras = {
      event_code: lecture.event.code,
      firstname: lecture.person.firstname,
      lastname: lecture.person.lastname,
      affiliation: lecture.person.affiliation,
      scheduled_time: start_time
    }
    lecture.attributes.merge(extras)
  end

  def find_lecture
    return if bad_params
    begin
      event = Event.find(@json['event_id'])
      lecture = Lecture.find(@json['lecture_id'])
    rescue ActiveRecord::RecordNotFound
      go_away && return
    end
    @lecture = confirm_legacy_db_consistency(event, lecture)
  end

  def bad_params
    return true if request.request_method == 'GET'
    unless valid_parameters?
      go_away
      return true
    end
    return false
  end

  # safety check due to legacy_db SNAFU
  def confirm_legacy_db_consistency(event, lecture)
    if event && lecture && lecture.event_id == event.id
      return lecture
    else
      go_away && return
    end
  end

  def authenticated?
    @authenticated || unauthorized
  end

  def go_away
    head :bad_request
  end

  def valid_id?(id)
    return false if id.blank?
    id.to_i > 0
  end

  def valid_lecture?(lecture)
    return false if lecture.blank?
    lecture.is_a?(Hash)
  end

  def valid_parameters?
    @json['event_id'] && valid_id?(@json['lecture_id']) &&
      valid_lecture?(@json['lecture'])
  end
end
