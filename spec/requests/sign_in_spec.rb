# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Sign-in', type: :request do
  let(:url) { user_session_url }

  before do
    @user = create(:user)
    @event = create(:event_with_members)
    create(:membership, event: @event, person: @user.person)

    headers = {'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    @params = {
      user: {
        email: @user.email,
        password: @user.password
      }
    }
  end

  context 'Without auth_headers' do
    it 'provides Authorization token with valid credentials' do
      # 'Accept' => 'application/json',
      # 'Content-Type' => 'application/json',
      params = {
        user: {
          email: @user.email,
          password: 'foo' + @user.password
        }
      }
      post url, params: params

      puts "\nparams: #{@response.pretty_inspect}\n"
      puts "\nresponse.request.methods: #{@response.request.methods}\n"


      expect(response.cookies['_workshops_session']).not_to be_nil
    end

    it 'does not provide Authorization token with invalid credentials' do
      params = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        user: {
          email: @user.email,
          password: 'foo'
        }
      }
      post url, params: params
      expect(response.header['Authorization']).to be_blank
    end
  end

  context 'With auth_headers & valid credentials' do
    before do
      post url, params: @params
    end

    it 'authenticates' do
      expect(controller.current_user).to eq(@user)
      flash_notice = response.request.flash.to_hash['notice']
      expect(flash_notice).to eq('Signed in successfully.')
    end

    it 'includes JWT auth token in response header' do
      expect(response.header['Authorization']).to match(/Bearer/)
    end

    it 'the character case of the email does not matter' do
      post url, params: @params.merge(user: { email: @user.email.upcase })
      flash_notice = response.request.flash.to_hash['notice']
      expect(flash_notice).to eq('Signed in successfully.')
    end

    it 'redirects to welcome page' do
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_path)
    end
  end

  context 'With invalid credentials or other issues' do
    before :each do
      logout(@user)
    end

    it 'fails to authenticate with wrong password' do
      post url, params: @params.merge(user: { password: 'foo'} )

      expect(controller.current_user).to be_nil
      flash_notice = response.request.flash.to_hash['alert']
      expect(flash_notice).to eq('Invalid Email or password.')
    end

    it 'Denies logins to non-admin users who have no memberships' do
      @user.member!
      @user.person.memberships.destroy_all

      post url, params: @params

      expect(controller.current_user).to be_nil
      flash_notice = response.request.flash.to_hash['error']
      expect(flash_notice).to eq('This account is not associated to any events.')
    end

    it 'Denies participants with memberships but who have not been invited' do
      @user.member!
      @user.person.memberships.destroy_all
      create(:membership, person: @user.person,
        attendance: 'Not Yet Invited', role: 'Participant')

      post url, params: @params

      expect(controller.current_user).to be_nil
      flash_notice = response.request.flash.to_hash['error']
      expect(flash_notice).to eq('This account is not associated to any events.')
    end

    it 'Allows organizers with memberships and declined attendance' do
      @user.member!
      @user.person.memberships.destroy_all
      create(:membership, person: @user.person, attendance: 'Declined',
                            role: 'Organizer')

      post url, params: @params

      expect(controller.current_user).to eq(@user)
      flash_notice = response.request.flash.to_hash['notice']
      expect(flash_notice).to eq('Signed in successfully.')
    end
  end
end

