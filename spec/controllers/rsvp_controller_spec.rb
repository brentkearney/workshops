# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe RsvpController, type: :controller do
  describe '#index' do
    it 'redirects to event list without event in url' do
      get :index
      expect(response).to redirect_to(events_path)
    end

    it 'redirects to event page without OTP in the url' do
      event = create(:event)
      get :index, event_id: event.code
      expect(response).to redirect_to(event_path(event))
    end
  end
end
