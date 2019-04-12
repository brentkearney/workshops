
# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'
require 'factory_bot_rails'

describe Api::V1::LecturesController, type: :request do
  before do
    @event = create(:event, start_date: Date.yesterday)
    @lecture = create(:lecture, event: @event)
    create(:schedule, lecture: @lecture, event: @event)
    @api_key = Setting.Site['LECTURES_API_KEY']
    @payload = {
        api_key: @api_key,
        lecture_id: @lecture.id,
        event_id: @event.code,
        lecture: { title: 'A new title', tweeted: true }
    }
  end

  context '#update' do
    it 'authenticates with the correct api key' do
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_successful
    end

    it 'does not authenticate with an invalid api key' do
      @payload['api_key'] = '123'
      put "/api/v1/lectures.json", params: @payload.to_json

      expect(response).to be_unauthorized
    end

    it 'given appropriate keys and lecture data, it updates lectures' do
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_created
      expect(Lecture.find(@lecture.id).title).to eq('A new title')
    end

    it 'given invalid or missing lecture_id, it fails' do
      @payload[:lecture_id] = 'X'
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:lecture_id)
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request
    end

    it 'given invalid or missing event_id, it fails' do
      @payload[:event_id] = 'X'
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:event_id)
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request
    end

    it 'given missing, invalid or empty lecture, it fails' do
      @payload['lecture'] = {}
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload['lecture'] = Array.new
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request

      @payload.delete(:lecture)
      put "/api/v1/lectures.json", params: @payload.to_json
      expect(response).to be_bad_request
    end
  end

  context '#lectures_on' do
    context 'authentication test' do
      it 'authenticates with api key in the request header' do
        get "/api/v1/lectures_on/2019-04-10/#{ERB::Util.url_encode(@lecture.room)}.json", headers: { 'HTTP_API_KEY' => @api_key }
        expect(response).to be_successful
      end
    end

    context 'stub authentication' do
      before do
        allow_any_instance_of(Api::V1::LecturesController).to receive(:authenticated?).and_return(true)
        allow_any_instance_of(Api::V1::BaseController).to receive(:authenticate_user_from_token!).and_return(true)
        start_time = (@event.start_date + 1.days).to_time
                                               .in_time_zone(@event.time_zone)
                                               .change({ hour:11, min:0})
        end_time = start_time + 1.hour
        3.times do
          lecture = create(:lecture, event: @event, start_time: start_time, end_time: end_time)
          create(:schedule, lecture: lecture, event: @event, start_time: start_time, end_time: end_time)
          start_time = end_time + 1.hour
          end_time = start_time + 1.hour
        end
        @date = @lecture.start_time.strftime("%Y-%m-%d")
      end

      it 'returns the lecture schedule for the given day' do
        get "/api/v1/lectures_on/#{@date}/#{ERB::Util.url_encode(@lecture.room)}.json"
        json = JSON.parse(response.body)

        Lecture.all.each do |lecture|
          record = json.select {|item| item['lecture']['id'].to_i == lecture.id }.first
          expect(record['lecture']['title']).to eq(lecture.title)
          expect(record['scheduled_for']['start_time']).to eq(record['lecture']['start_time'])
        end
      end

      it 'sets scheduled_for times to empty strings if no schedule item found' do
        schedule = Schedule.where(lecture_id: @lecture.id).first
        expect(schedule).not_to be_nil
        schedule.delete
        expect(Lecture.find_by_id(@lecture.id)).not_to be_blank

        get "/api/v1/lectures_on/#{@date}/#{ERB::Util.url_encode(@lecture.room)}.json"
        json = JSON.parse(response.body)
        lecture = json.select {|j| j['lecture']['id'].to_i == @lecture.id }.first

        expect(lecture['scheduled_for']['start_time']).to be_empty
        expect(lecture['scheduled_for']['end_time']).to be_empty
      end
    end
  end

  context '#lecture_data' do
    context 'authentication test' do
      it 'authenticates with api key in the request header' do
        get "/api/v1/lecture_data/#{@lecture.id}.json", headers: { 'HTTP_API_KEY' => @api_key }
        expect(response).to be_successful
      end
    end

    context 'stub authentication' do
      before do
        allow_any_instance_of(Api::V1::LecturesController).to receive(:authenticated?).and_return(true)
        allow_any_instance_of(Api::V1::BaseController).to receive(:authenticate_user_from_token!).and_return(true)
        get "/api/v1/lecture_data/#{@lecture.id}.json"
        @json = JSON.parse(response.body)
        puts "#{@json.pretty_inspect}"
      end

      it 'returns a complete lecture record' do
        @lecture.attributes.each do |key, value|
          next if key =~ /_time|_at/
          expect(@json['lecture'][key]).to eq(value)
        end
      end

      it 'returns person correspondance info' do
        expect(@json['person']['salutation']).to eq(@lecture.person.salutation)
        expect(@json['person']['firstname']).to eq(@lecture.person.firstname)
        expect(@json['person']['lastname']).to eq(@lecture.person.lastname)
        expect(@json['person']['email']).to eq(@lecture.person.email)
      end

      it 'returns essential event information' do
        expect(@json['event']['code']).to eq(@lecture.event.code)
        expect(@json['event']['name']).to eq(@lecture.event.name)
        expect(@json['event']['event_type']).to eq(@lecture.event.event_type)
        expect(@json['event']['start_date']).to eq(@lecture.event.date)
        expect(@json['event']['location']).to eq(@lecture.event.location)
      end
    end
  end
end
