# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Sends signals to the BIRS Automated Video Recording System
class LectureRecording
  attr_reader :response_message

  def initialize(lecture, users_name)
    @lecture = lecture
    @users_name = users_name
    @recording_host = GetSetting.site_setting('recording_api')
    @recording_host = nil if @recording_host == 'recording_api not set'
  end

  def start
    return if @recording_host.nil?

    Rails.logger.debug "\n\nLectureRecording.start is_recording? #{@lecture.is_recording}\n\n"
    if @lecture.is_recording
      @response_message = "#{@lecture.person.name}: #{@lecture.title}
        is already recording.".squish
      return
    end

    @lecture.update_columns(is_recording: true, updated_by: @users_name)
    tell_recording_system("RECORD-START\n")
    @response_message = "Starting recording for #{@lecture.person.name}:
                    #{@lecture.title}...".squish
  end

  def stop
    return if @recording_host.nil?
    @lecture.update_columns(is_recording: false, updated_by: @users_name,
                            filename: 'pending')
    tell_recording_system("RECORD-STOP\n")
    @response_message = "Recording Stopped."
  end


  private

  def tell_recording_system(command)
    host_ip, port = @recording_host.split(':')
    ConnectToRecordingSystemJob.perform_later(command, host_ip, port)
  end
end
