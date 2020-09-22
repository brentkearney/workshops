# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "LectureRecording" do
  before do
    @event = add_lectures_on(Date.current)
    @lecture = @event.lectures.first
  end

  context '.initialize' do
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
      expect(GetSetting).to receive(:site_setting).with('recording_api').and_return(nil)
      expect(LectureRecording.new(@lecture, 'Some User').start).to be_nil
    end

    it 'updates lecture.is_recording to true' do
      expect(@lecture.is_recording).to be_falsey
      @lr.start
      expect(@lecture.is_recording).to be_truthy
    end

    it 'launches ConnectToRecordingSystemJob' do
      allow(ConnectToRecordingSystemJob).to receive(:perform_later)
      @lr.start
      expect(ConnectToRecordingSystemJob).to have_received(:perform_later)
    end
  end

  context '.stop' do
    before do
      @lecture.is_recording = true
      @lecture.save
      @lr = LectureRecording.new(@lecture, 'Some User')
    end

    it 'returns nil if recording_api Setting is not set' do
      expect(GetSetting).to receive(:site_setting).with('recording_api').and_return(nil)
      expect(LectureRecording.new(@lecture, 'Some User').start).to be_nil
    end

    it 'updates lecture.is_recording to false' do
      expect(@lecture.is_recording).to be_truthy
      @lr.stop
      expect(@lecture.is_recording).to be_falsey
    end

    it 'launches ConnectToRecordingSystemJob' do
      allow(ConnectToRecordingSystemJob).to receive(:perform_later)
      @lr.start
      expect(ConnectToRecordingSystemJob).to have_received(:perform_later)
    end
  end
end
