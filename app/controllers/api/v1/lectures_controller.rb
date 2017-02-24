# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Api::V1::LecturesController < Api::V1::BaseController
  before_filter :find_lecture
  respond_to :json

  # PATCH/PUT /lectures/1.json
  def update
    @json['lecture']['updated_by'] = @updated_by
    @lecture.assign_attributes(@json['lecture'])

    respond_to do |format|
      if @lecture.save
        format.json { render nothing: true, status: :created }
      else
        format.json { render json: @lecture.errors, status: :unprocessable_entity }
      end
    end
  end

  def method_missing(foo = false)
    go_away
  end

  def find_lecture
    @lecture = nil
    if valid_parameters?
      begin
        event = Event.find(@json['event_id'])
        lecture = Lecture.find(@json['lecture_id'])
      rescue ActiveRecord::RecordNotFound
        go_away
        return
      end
      if confirm_legacy_db_consistency(event, lecture)
        @lecture = lecture
      end
    else
      go_away
    end
  end

  private

  # safety check due to legacy_db SNAFU
  def confirm_legacy_db_consistency(event, lecture)
    event && lecture && lecture.event_id == event.id || go_away
  end

  def is_authenticated?
    @authenticated
  end

  def go_away
    render nothing: true, status: :bad_request
  end

  def valid_parameters?
    @json['event_id'] && @json['lecture_id'] && @json.has_key?('lecture') &&
        @json['lecture'].is_a?(Hash) && !@json['lecture'].empty?
  end
end
