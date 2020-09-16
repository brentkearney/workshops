# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "LectureRecording" do
  context '.initialize' do
    before do
      @event = add_lectures_on(Date.current)
      @lecture = @event.lectures.first
    end

    it "initializes with lecture, user's name parameter" do
      lr = LectureRecording.new(@lecture, 'Some User')
      expect(lr).to be_a(LectureRecording)
    end
  end

  context '.start' do
    before do
      @lr = LectureRecording.new(@lecture, 'Some User')
    end

    it 'returns nil if recording_api Setting is not set' do
      expect(@lr.start).to be_nil
    end

    it 'runs .tell_recording_system(:start)' do
      expect(GetSetting).to receive(:site_setting).with('recording_api').and_return('host')
      ActiveJob::Base.queue_adapter = :test

      expect {
        @lr.start
      }.to change {
        ActiveJob::Base.queue_adapter.enqueued_jobs.count
      }.by 1
    end
  end
end
