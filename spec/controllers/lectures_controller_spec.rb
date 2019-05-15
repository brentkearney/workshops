# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe LecturesController, type: :controller do
  describe 'RSS feeds' do
    context 'today' do
      before do
        @event = add_lectures_on(Date.current)
        @room = Lecture.last.room
      end

      it 'assigns @lectures' do
        get :today, params: { room: @room, format: 'rss' }

        expect(response.status).to eq(200)
        expect(assigns(:lectures)).not_to be_empty
      end

      it 'redirects html format requests to schedule index page' do
        get :today, params: { room: @room, format: 'html' }

        expect(response.status).to eq(302)
        expect(subject).to redirect_to(event_schedule_index_url(@event))
      end

      it 'renders RSS XML' do
        get :today, params: { room: @room, format: 'rss' }

        expect(response).to render_template('lectures/today')
        expect(response.content_type).to eq("application/rss+xml")
      end

      it 'produces emtpy feed if no lectures scheduled today' do
        Lecture.destroy_all
        get :today, params: { room: @room, format: 'rss' }

        expect(response.status).to eq(200)
        expect(assigns(:lectures)).to be_empty
      end
    end

    context 'current' do
      before do
        @event = create(:event, current: true)
        start_time = Time.now
        end_time = start_time + 40.minutes
        @lecture = create(:lecture, event: @event, start_time: start_time,
                                 end_time: end_time)
        @room = @lecture.room
      end

      it 'assigns @lecture' do
        get :current, params: { room: @room, format: 'rss' }

        expect(response.status).to eq(200)
        expect(assigns(:lecture)).to eq(@lecture)
      end

      it 'redirects html format requests to schedule index page' do
        get :current, params: { room: @room, format: 'html' }

        expect(response.status).to eq(302)
        expect(subject).to redirect_to(event_schedule_index_url(@event))
      end

      it 'renders RSS XML' do
        get :current, params: { room: @room, format: 'rss' }

        expect(response).to render_template('lectures/current')
        expect(response.content_type).to eq("application/rss+xml")
      end

      it 'produces emtpy feed if no current lecture' do
        Lecture.destroy_all
        get :current, params: { room: @room, format: 'rss' }

        expect(response.status).to eq(200)
        expect(assigns(:lectures)).to be_blank
      end
    end
  end

  context 'next' do
    before do
      @event = create(:event, current: true)
      start_time = Time.now + 2.hours
      end_time = start_time + 40.minutes
      @lecture = create(:lecture, event: @event, start_time: start_time,
                               end_time: end_time)
      @room = @lecture.room
    end

    it 'assigns @lecture' do
      get :next, params: { room: @room, format: 'rss' }

      expect(response.status).to eq(200)
      expect(assigns(:lecture)).to eq(@lecture)
    end

    it 'redirects html format requests to schedule index page' do
      get :next, params: { room: @room, format: 'html' }

      expect(response.status).to eq(302)
      expect(subject).to redirect_to(event_schedule_index_url(@event))
    end

    it 'renders RSS XML' do
      get :next, params: { room: @room, format: 'rss' }

      expect(response).to render_template('lectures/next')
      expect(response.content_type).to eq("application/rss+xml")
    end

    it 'produces emtpy feed if no current lecture' do
      Lecture.destroy_all
      get :next, params: { room: @room, format: 'rss' }

      expect(response.status).to eq(200)
      expect(assigns(:lectures)).to be_blank
    end
  end
end
