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
    @rest_url = Setting.Site['legacy_api']
    @rest_url = nil if ENV['APPLICATION_HOST'].include?('staging')
    @rest_url = nil if ENV['RAILS_ENV'] == 'development'
  end

  # get a list of events within a given date range
  def list_events(from_date, to_date)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/event_list",
                               params: { year1: from_date, year2: to_date }))
  end

  # get data for specific events
  def get_event_data(event_id)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/event_data/#{event_id}"))
  end

  # get event data for given year
  def get_event_data_for_year(year)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/event_data_for_year/#{year}"))
  end

  # get membership data for an event
  def get_members(event)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/members/#{event.code}"))
  end

  # get a member record data
  def get_member(membership)
    return if @rest_url.blank?
    mbr = { event_id: membership.event.code,
            person_id: membership.person.legacy_id }
    JSON.parse((RestClient.get "#{@rest_url}/get_member", params: mbr))
  end

  # get a person record data
  def get_person(legacy_id)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/get_person/#{legacy_id}"))
  end

  # search legacy db for person by email
  def search_person(email)
    return if @rest_url.blank?
    email = email.remove_non_ascii
    JSON.parse((RestClient.get "#{@rest_url}/search_person/#{email}"))
  end

  # add or update person record
  def add_person(person)
    return if @rest_url.blank?
    person.grants = person.grants.join(', ') unless person.grants.blank?
    JSON.parse((RestClient.post "#{@rest_url}/add_person",
                                person.to_json,
                                content_type: :json, accept: :json))
  end

  # add new member to event
  def add_member(membership:, event_code:, person:, updated_by:)
    return if @rest_url.blank?
    person.grants = person.grants.join(', ') unless person.grants.blank?
    remote_membership = membership.attributes.merge(
      workshop_id: event_code,
      member_id: membership.id,
      person:      person.as_json.merge(new_id: person.id),
      updated_by:  updated_by,
      invite_reminders: nil
    )
    remote_membership = update_booleans(remote_membership)

    JSON.parse((RestClient.post "#{@rest_url}/add_member/#{event_code}",
                                remote_membership.to_json,
                                content_type: :json,
                                accept: :json))
  end

  # add new members to event
  def add_members(event_code:, members:, updated_by:)
    return if @rest_url.blank?
    responses = []
    members.each do |member|
      person = member.person.attributes.merge(updated_by: membership.updated_by)
      responses[] = add_member(membership: member,
                               event_code: event_code,
                               person:  person,
                               updated_by: updated_by)
    end
  end

  # update membership & person record
  def update_member(membership_id)
    return if @rest_url.blank?
    member = Membership.find_by_id(membership_id)
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
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/event_lectures/#{event_id}"))
  end

  def get_lecture(legacy_id)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/get_lecture/#{legacy_id}"))
  end

  # get legacy_id of a given lecture
  def get_lecture_id(lecture)
    return if @rest_url.blank?
    day = lecture.start_time.strftime('%Y-%m-%d')
    u = "#{@rest_url}/new_lecture_id/#{lecture.event.code}/#{day}/#{lecture.id}"
    lecture_hash = JSON.parse((RestClient.get u))
    lecture_hash['legacy_id'].to_i
  end

  # add a lecture
  def add_lecture(lecture)
    return if @rest_url.blank?
    event_id = lecture.event.code
    lecture.person_id = lecture.person.legacy_id
    url = "#{@rest_url}/add_lecture/#{event_id}"
    RestClient.post url, lecture.to_json, content_type: :json, accept: :json
    get_lecture_id(lecture) unless lecture.local_only
  end

  def delete_lecture(lecture_id)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/delete_lecture/#{lecture_id}"))
  end

  def delete_member(membership)
    return if @rest_url.blank?
    url = "#{@rest_url}/delete_membership/#{membership['event_id']}"
    RestClient.post url, membership.to_json, content_type: :json, accept: :json
  end

  def check_rsvp(otp)
    return if @rest_url.blank?
    JSON.parse((RestClient.get "#{@rest_url}/check_rsvp/#{otp}"))
  end

  def replace_person(replace_legacy_id, replace_with_legacy_id)
    return if @rest_url.blank?
    return if replace_legacy_id == replace_with_legacy_id
    replace = {
      person_to_replace: replace_legacy_id,
      replace_person_with: replace_with_legacy_id
    }
    url = "#{@rest_url}/replace_person"
    RestClient.post url, replace.to_json, content_type: :json, accept: :json
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
end
