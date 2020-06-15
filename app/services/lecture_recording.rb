# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Sends signals to the BIRS Automated Video Recording System
class LectureRecording
  require 'socket'

  def initialize(lecture, user)
    @lecture = lecture
    @user = user
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


  def tell_recording_system(command)
    return if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'staging'
    if command == :start
      start_stop_cmd = "RECORD-START\n"
      @lecture.update_columns(is_recording: true, updated_by: @user)
    elsif command == :stop
      start_stop_cmd = "RECORD-STOP\n"
      @lecture.update_columns(is_recording: false, updated_by: @user)
    end

    return if start_stop_cmd.blank? || @recording_host.nil?
    execute_commands(start_stop_cmd, @recording_host.split(':'))
  end

  def execute_commands(start_stop_cmd, host_info)
    Thread.new do
      begin
        socket = TCPSocket.new host_info.first, host_info.last.to_i
        socket.puts start_stop_cmd
        socket.close
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, IOError => e
        Rails.logger.debug "\n\nError connecting to recording system: #{e.message}\n\n"
        msg = e.message + "\n\n"
        msg << e.backtrace.to_s
        StaffMailer.notify_sysadmin(@lecture.event, msg).deliver_now
      end
    end
  end
end
