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
    go_away && return if invalid_event_code?

    event = setup_event(@json['event'])
    return unless event.is_a?(Event)

    return invalid_event(event) unless event.save

    updated_by = @json['updated_by'] || 'Events API'
    memberships = AddMemberships.new(@json['memberships'], event, updated_by)

    if memberships.save
      respond_to do |format|
        format.json { head :created }
      end
    else
      respond_to do |format|
        format.json { head :unprocessable_entity }
      end
    end
  end


  # POST /api/v1/events/sync/1.json
  def sync
    go_away && return if invalid_event_code?

    event = Event.find_by_code(@json['event_id'])
    go_away && return if event.nil?

    SyncEventMembersJob.perform_later(event.id)

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def method_missing(method_name, *arguments, &block)
    go_away
    super
  end

  def respond_to_missing?(method_name, include_private = false)
    Rails.logger.debug "\n\n******** Api::V1::EventsController missing method: #{method_name} ********\n\n"
    super
  end

  def render_without_wicked_pdf(arg); end

  private

  def event_exists(event)
    msg = "#{event.code} already exists, cannot add again."
    StaffMailer.notify_sysadmin(event, msg).deliver_now

    respond_to do |format|
      format.json { head :unprocessable_entity }
    end
  end

  def assign_defaults(event)
    if (event.max_participants.blank? || event.max_participants.zero?)
      event.max_participants = GetSetting.max_participants(event.location)
    end

    event.max_observers = GetSetting.max_observers(event.location)
    event.max_virtual = GetSetting.max_virtual(event.location)

    if event.time_zone.blank?
      tz = GetSetting.location(event.location, 'Timezone')
      event.time_zone = tz.blank? ? GetSetting.default_timezone : tz
    end

    event.event_format = 'Hybrid' if event.event_format.blank?
    event.event_type.gsub!(/^(\d)-Day/, '\1 Day')

    event
  end

  def setup_event(event_attributes)
    event = Event.new(data_import: true)
    event.assign_attributes(event_attributes)

    return event_exists(event) if Event.find(event.code).present?

    if GetSetting.location(event.location, 'Name').blank?
      return unknown_location(event)
    end

    assign_defaults(event)
  end

  def unknown_location(event)
    msg = "#{event.code} has an unknown location: #{event.location}."
    StaffMailer.notify_sysadmin(event, msg).deliver_now

    respond_to do |format|
      format.json { render json: { error: msg }, status: :unprocessable_entity }
    end
  end

  def invalid_event(event)
    StaffMailer.notify_sysadmin(event, event.errors).deliver_now

    respond_to do |format|
      format.json { render json: event.errors, status: :unprocessable_entity }
    end
  end

  def authenticated?
    @authenticated || unauthorized
  end

  def go_away
    head :bad_request
  end

  def invalid_event_code?
    return true if @json['event'].blank? || @json['event']['code'].blank?

    !@json['event']['code'].match?(/#{GetSetting.code_pattern}/)
  end
end
