# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Sends signals to the BIRS Automated Video Recording System
class LectureRecording
  require 'socket'

  def initialize(lecture)
    @lecture = lecture
    @recording_host = GetSetting.site_setting('recording_api')
    @recording_host = nil if @recording_host == 'recording_api not set'
  end

  def start
    return if @recording_host.nil?
    update_lecture(:start)
    tell_recording_system(:start)
  end

  def stop
    return if @recording_host.nil?
    update_lecture(:stop)
    tell_recording_system(:stop)
  end


  private

  def update_lecture(start_stop)
    case start_stop
    when :start
      talk_length = ((@lecture.end_time - @lecture.start_time) * 24 * 60).to_i.abs
      new_end = @lecture.end_time + talk_length.minutes

      @lecture.update_columns(start_time: DateTime.now, end_time: new_end, is_recording: true)
    when :stop
      @lecture.update_columns(is_recording: false)
    end
  end

  def tell_recording_system(command)
    return if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'staging'
    start_stop_cmd = "RECORD-START\n" if command == :start
    start_stop_cmd = "RECORD-STOP\n" if command == :stop
    return if start_stop_cmd.blank? || @recording_host.nil?
    host_info = @recording_host.split(':')

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
