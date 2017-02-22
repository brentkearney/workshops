# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'
require 'factory_girl_rails'

describe Api::V1::LecturesController do
  context '#update' do
    before do
      @event = create(:event)
      @lecture = create(:lecture, event: @event)
      create(:schedule, lecture: @lecture, event: @event)
      key = ENV['LECTURES_API_KEY']
      @payload = {
          api_key: key,
          lecture_id: @lecture.id,
          event_id: @event.code,
          lecture: { title: 'A new title', tweeted: true }
      }
    end

    it 'given appropriate keys and lecture data, it updates lectures' do
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_created
      expect(Lecture.find(@lecture.id).title).to eq('A new title')
    end

    it 'given invalid api key, it fails' do
      @payload['api_key'] = '123'
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_unauthorized
    end

    it 'given invalid or missing lecture_id, it fails' do
      @payload['lecture_id'] = 'X'
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:lecture_id)
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request
    end

    it 'given invalid or missing event_id, it fails' do
      @payload['event_id'] = 'X'
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:event_id)
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request
    end

    it 'given missing, invalid or empty lecture, it fails' do
      @payload['lecture'] = {}
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request

      @payload['lecture'] = Array.new
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:lecture)
      put "/api/v1/lectures.json", @payload.to_json
      expect(response).to be_bad_request
    end

    # Leave the schedule alone (for now)
    # it 'also updates the linked Schedule item' do
    #   put "/api/v1/lectures.json", @payload.to_json
    #   expect(response).to be_created
    #   s = Schedule.find_by_lecture_id(@lecture.id)
    #   expect(s).not_to be_nil
    #   expect(s.name).to include('A new title')
    # end

  end
end
