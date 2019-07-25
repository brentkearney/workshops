# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'API Sign-in', type: :request do
  let(:url) { new_api_user_session_path }

  before do
    @user = create(:user, role: :staff)
    @event = create(:event_with_members)
    @valid_params = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      api_user: {
        email: @user.email,
        password: @user.password
      }
    }
  end

  it 'returns an Authorization token, given valid credentials' do
    post url, params: @valid_params

    expect(response.header['Authorization']).to match(/Bearer/)
  end

  it 'does not return an Authorization token for html requests' do
    params = @valid_params.merge(
      'Accept' => 'text/html',
      'Content-Type' => 'text/html',
    )

    post '/api/login.html', params: params

    expect(response).to have_http_status(406)
    expect(response.header['Authorization']).to be_blank
  end

  it 'does not provide Authorization token with invalid credentials' do
    params = @valid_params.merge(
      api_user: {
        password: 'foo'
      }
    )
    post url, params: params
    expect(response.header['Authorization']).to be_blank
  end
end

