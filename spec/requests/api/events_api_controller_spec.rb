# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'
require 'factory_bot_rails'

describe Api::V1::EventsController do
  before do
    @key = GetSetting.site_setting('EVENTS_API_KEY')
  end

  context '#create' do
    before do
      @event = build(:event)
      @payload = {
          api_key: @key,
          event_id: @event.code,
          event: @event.as_json
      }
    end

    it 'authenticates with the correct api key' do
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_successful
    end

    it 'does not authenticate with an invalid api key' do
      @payload['api_key'] = '123'
      post "/api/v1/events.json", params: @payload.to_json

      expect(response).to be_unauthorized
    end

    it 'given appropriate keys and event data, it creates an event' do
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_created
      expect(Event.find(@event.code)).not_to be_nil
    end

    it 'given invalid or missing event code, it fails' do
      @payload[:event_id] = 'X'
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:event_id)
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_bad_request
    end

    it 'given event code of existing event, it fails' do
      existing_event = create(:event)
      new_payload = {
        api_key: @payload[:api_key],
        event_id: existing_event.code,
        event: existing_event.as_json
      }

      post "/api/v1/events.json", params: new_payload.to_json
      expect(response).to be_bad_request
    end

    it 'given missing, invalid or empty event, it fails' do
      @payload['event'] = {}
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload['event'] = Array.new
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:event)
      post "/api/v1/events.json", params: @payload.to_json
      expect(response).to be_bad_request
    end
  end

  context '#sync' do
    before do
      @event = create(:event_with_members)
      @payload = {
          api_key: @key,
          event_id: @event.code,
          event: ''
      }
    end

    it 'queues an ActiveJob job to sync events in the background' do
    expect { post "/api/v1/events/sync.json", params: @payload.to_json }
      .to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end

    it 'sends given event_id to SyncEventMembersJob' do
      allow(SyncEventMembersJob).to receive(:perform_later)

      post "/api/v1/events/sync.json", params: @payload.to_json

      expect(SyncEventMembersJob).to have_received(:perform_later).with(@event.id)
    end

    it 'given invalid event_id, it fails' do
      @payload['event_id'] = 'foo'
      post "/api/v1/events/sync.json", params: @payload.to_json
      expect(response).to be_bad_request
    end
  end
end
