# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'JSON API Access', type: :request do
  before do
    @user = create(:user, role: :staff)
    @event = create(:event_with_members)

    params = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      api_user: {
        email: @user.email,
        password: @user.password
      }
    }
    post new_api_user_session_path, params: params

    auth_token = response.header['Authorization']
    @auth_headers = {
      'Authorization' => auth_token,
      'Accept' => 'application/json'
    }
  end

  it 'Authorization token can be used to access protected data' do
    memberships_url = event_memberships_url(@event) + '.json'
    get memberships_url, params: {}, headers: @auth_headers

    expect(response.status).to eq(200)
    member = @event.memberships.first
    expect(response.body).to include(member.staff_notes)
    expect(response.body).to include(member.person.email)
  end

  it 'does not provide access to personal info for non-staff users' do
    @user.member!

    memberships_url = event_memberships_url(@event) + '.json'
    get memberships_url, params: {}, headers: @auth_headers

    member = @event.memberships.first
    expect(response.body).not_to include(member.person.email)
    expect(response.body).to include(member.person.name)

    @user.staff!
  end

  it 'authorized users can post updates via json' do
    member = @event.memberships.last
    new_phone = '123-456-7890'
    new_note = 'New note'
    expect(member.person.phone).not_to eq(new_phone)
    expect(member.staff_notes).not_to eq(new_note)

    params = {
      membership: {
        staff_notes: new_note,
        person_attributes: { phone: new_phone }
      }
    }
    membership_url = event_membership_url(@event, member) + '.json'
    patch membership_url, params: params, headers: @auth_headers

    expect(response.status).to eq(200)
    updated_member = Membership.find(member.id)
    expect(updated_member.staff_notes).to eq(new_note)
    expect(updated_member.person.phone).to eq(new_phone)
  end

  it 'logout destroys auth token and denies further access' do
    headers = @auth_headers.dup
    delete api_logout_path, params: headers

    memberships_url = event_memberships_url(@event) + '.json'
    get memberships_url, params: {}, headers: headers

    expect(response.status).to eq(302)
    member = @event.memberships.first
    expect(response.body).not_to include(member.person.email)
  end
end
