# Copyright (c) 2018 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Connects to internal API for legacy database
class LegacyConnector
  require 'rest_client'

  def initialize
    @rest_url = GetSetting.site_setting('legacy_api')
    @rest_url = nil if not_production_or_test
  end

  def not_production_or_test
    @rest_url == 'legacy_api not set' ||
    ENV['APPLICATION_HOST'].include?('staging') ||
    ENV['RAILS_ENV'] == 'development'
  end

  # get a list of events within a given date range
  def list_events(from_date, to_date)
    get_from("event_list", { year1: from_date, year2: to_date })
  end

  # add a new event to legacy db
  def add_event(event)
    response = JSON.parse(post_to("event_add/#{event.code}", event))
    if response.empty?
      add_members(event_code: event.code, members: event.memberships,
                  updated_by: 'Workshops')
    else
      send_error_report(nil, JSON.parse(response))
    end
  end

  # get data for specific events
  def get_event_data(event_id)
    get_from("event_data/#{event_id}")
  end

  # get event data for given year
  def get_event_data_for_year(year)
    get_from("event_data_for_year/#{year}")
  end

  # get membership data for an event
  def get_members(event)
    get_from("members/#{event.code}")
  end

  # get a member record data
  def get_member(membership)
    member_params = { event_id: membership.event.code,
                      person_id: membership.person.legacy_id }

    get_from("get_member", member_params)
  end

  # get a person record data
  def get_person(legacy_id)
    get_from("get_person/#{legacy_id}")
  end

  # search legacy db for person by email
  def search_person(email)
    email = email.remove_non_ascii
    get_from("search_person/#{email}")
  end

  # add or update person record
  def add_person(person)
    person.grants = person.grants.join(', ') unless person.grants.blank?

    JSON.parse(post_to("add_person", person))
  end

  # add new member to event
  def add_member(membership:, event_code:, person:, updated_by:)
    person.grants = person.grants.join(', ') unless person.grants.blank?
    remote_membership = membership.attributes.merge(
      workshop_id: event_code,
      member_id: membership.id,
      person:      person.as_json.merge(new_id: person.id),
      updated_by:  updated_by,
      invite_reminders: nil
    )
    remote_membership = update_booleans(remote_membership)

    JSON.parse(post_to("add_member/#{event_code}", remote_membership))
  end

  # add new members to event
  def add_members(event_code:, members:, updated_by:)
    members.each_with_object([]) do |member, responses|
      person = member.person #.attributes.merge(updated_by: member.updated_by)
      responses << add_member(membership: member,
                              event_code: event_code,
                              person:  person,
                              updated_by: updated_by)
    end
  end

  # update membership & person record
  def update_member(membership_id)
    member = Membership.find_by_id(membership_id)
    if member.blank?
      send_error_report(nil, "No membership with id #{membership_id}.")
      return
    end

    member.updated_at = member.updated_at
                              .in_time_zone('Pacific Time (US & Canada)')
                              .strftime('%Y-%m-%d %H:%M:%S')
    unless member.replied_at.blank?
      member.replied_at = member.replied_at
                                .in_time_zone('Pacific Time (US & Canada)')
                                .strftime('%Y-%m-%d %H:%M:%S')
    end

    unless member.invited_on.blank?
      member.invited_on = member.invited_on
                                .in_time_zone('Pacific Time (US & Canada)')
                                .strftime('%Y-%m-%d %H:%M:%S')
    end

    if member.attendance == 'Confirmed'
      person = member.person
      person.updated_at = person.updated_at
                                .in_time_zone('Pacific Time (US & Canada)')
                                .strftime('%Y-%m-%d %H:%M:%S')
    end

    # add_member() adds or updates memberships
    add_member(membership: member,
               event_code: member.event.code,
               person: member.person,
               updated_by: member.updated_by)
  end

  # update an event's members
  def update_members(event_id, members); end

  # get an events lectures
  def get_lectures(event_id)
    get_from("event_lectures/#{event_id}")
  end

  def get_lecture(legacy_id)
    get_from("get_lecture/#{legacy_id}")
  end

  # get legacy_id of a given lecture
  def get_lecture_id(lecture)
    code = lecture.event.code
    day = lecture.start_time.strftime('%Y-%m-%d')

    lecture_hash = get_from("new_lecture_id/#{code}/#{day}/#{lecture.id}")
    lecture_hash['legacy_id'].to_i
  end

  # add a lecture
  def add_lecture(lecture)
    lecture.person_id = lecture.person.legacy_id || 0
    event = lecture.event
    event.time_zone = GetSetting.default_timezone if event.time_zone.blank?
    lecture.start_time = lecture.start_time.in_time_zone(event.time_zone)
    lecture.end_time = lecture.end_time.in_time_zone(event.time_zone)

    post_to("add_lecture/#{event.code}", lecture)
    get_lecture_id(lecture) unless lecture.local_only
  end

  def delete_lecture(lecture_id)
    get_from("delete_lecture/#{lecture_id}")
  end

  def delete_member(membership)
    post_to("delete_membership/#{membership['event_id']}", membership)
  end

  def check_rsvp(otp)
    get_from("check_rsvp/#{otp}")
  end

  def replace_person(replace_legacy_id, replace_with_legacy_id)
    return if replace_legacy_id == replace_with_legacy_id

    replace = {
      person_to_replace: replace_legacy_id,
      replace_person_with: replace_with_legacy_id
    }

    post_to("replace_person", replace)
  end

  def update_booleans(obj)
    new_obj = {}
    obj.each_pair do |k, v|
      v = 1 if v == true
      v = 0 if v == false
      new_obj[k] = v
    end
    new_obj
  end

  private

  def send_error_report(error, message = false)
    report = ErrorReport.new('LegacyConnector')
    report.add(self, (message || error))
    report.send_report
  end

  def get_from(url, params = {})
    return if @rest_url.blank?

    uri = "#{@rest_url}/#{url}"
    return JSON.parse(RestClient.get uri) if params.blank?

    return JSON.parse(RestClient.get uri, params: params)

  rescue => error
    send_error_report(error)
  end

  def post_to(url, params)
    return if @rest_url.blank?

    uri = @rest_url + '/' + url

    params = params.to_json
    return RestClient.post uri, params, content_type: :json, accept: :json

  rescue => error
    send_error_report(error)
  end
end
