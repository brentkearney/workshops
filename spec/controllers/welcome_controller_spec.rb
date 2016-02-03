# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do

  before do
    Event.destroy_all
    authenticate_for_controllers # sets @user, @person, @event, @membership
  end

  describe "#index" do
    it 'responds with success code' do
      get :index

      expect(response).to be_success
    end

    it 'renders :index' do
      get :index

      expect(response).to render_template(:index)
    end

    it 'assigns @heading' do
      get :index

      expect(assigns(:heading)).not_to be_empty
    end

    it "assigns @memberships to user's memberships" do
      get :index

      expect(assigns(:memberships)).to match_array(@person.memberships)
    end

    it 'orders @memberships by event date'
    it 'excludes from @memberships where attendance is Declined'
    it 'includes Declined memberships if role is Organizer'
    it 'excludes from @memberships where attendance is Not Yet Invited'
    it 'excludes from @memberships where role is Backup Participant'
    it 'excludes from @memberships where event is from more than 2 weeks ago'
    it 'runs background job to sync current events with remote db'
  end
end