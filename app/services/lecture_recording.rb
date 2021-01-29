# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Sends signals to the BIRS Automated Video Recording System
class LectureRecording
  attr_reader :flash_class, :flash_message

  def initialize(lecture, users_name)
    @lecture = lecture
    @users_name = users_name
    @recording_host = GetSetting.site_setting('recording_api')
    @recording_host = nil if @recording_host == 'recording_api not set'
  end

  def start
    return if @recording_host.nil? || already_recording?

    @lecture.update_columns(is_recording: true, updated_by: @users_name)
    tell_recording_system("RECORD-START\n")
    set_flash(msg_type: 'success', msg_kind: :start)
  end

  def already_recording?
    recording_lecture = @lecture.event.lectures.detect(&:is_recording)
    return false if recording_lecture.blank?

    set_flash(msg_type: 'error', msg_kind: :recording,
              recording_lecture: recording_lecture)
    return true
  end

  def set_flash(msg_type: 'notice', msg_kind:, recording_lecture: nil)
    @flash_class = msg_type

    case msg_kind
    when :start
      @flash_message = %Q{Starting recording for "#{@lecture.person.name}:
                    #{@lecture.title}"}.squish
    when :stop
      @flash_message = "Recording stopped."

    when :recording
      @flash_message = %Q{Already recording
        "#{recording_lecture.person.name}: #{recording_lecture.title}".}.squish
    end
  end

  def stop
    return if @recording_host.nil?
    @lecture.update_columns(is_recording: false, updated_by: @users_name,
                            filename: 'pending')
    tell_recording_system("RECORD-STOP\n")
    set_flash(msg_kind: :stop)
  end


  private

  def tell_recording_system(command)
    host_ip, port = @recording_host.split(':')
    ConnectToRecordingSystemJob.perform_later(command, host_ip, port)
  end
end
