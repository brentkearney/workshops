# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Sends signals to the BIRS Automated Video Recording System
class LectureRecording

  def initialize(lecture, users_name)
    @lecture = lecture
    @users_name = users_name
    @recording_host = GetSetting.site_setting('recording_api')
    @recording_host = nil if @recording_host == 'recording_api not set'
  end

  def start
    return if @recording_host.nil?
    tell_recording_system(:start)
  end

  def stop
    return if @recording_host.nil?
    tell_recording_system(:stop)
  end


  private

  def update_and_get_cmd(command)
    if command == :start
      @lecture.update_columns(is_recording: true, updated_by: @users_name)
      return "RECORD-START\n"
    elsif command == :stop
      @lecture.update_columns(is_recording: false, updated_by: @users_name)
      return "RECORD-STOP\n"
    end
  end

  def tell_recording_system(command)
    return if %w(test development).include? ENV['RAILS_ENV'] ||
      ENV['APPLICATION_HOST'].include?('staging')
    host_ip, port = @recording_host.split(':')
    ConnectToRecordingSystemJob.perform_later(update_and_get_cmd(command),
      host_ip, port)
  end
end
