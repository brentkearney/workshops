# app/jobs/delete_membership_job.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to video recording system to start/stop recording
class ConnectToRecordingSystemJob < ApplicationJob
  require 'socket'
  queue_as :urgent

  rescue_from(StandardError) do |e|
    Rails.logger.debug "\n\nError connecting to recording sys: #{e.message}\n\n"
    msg = e.message + "\n\n"
    msg << e.backtrace.to_s
    StaffMailer.notify_sysadmin(nil, msg).deliver_now

    retry_job wait: 5.seconds, queue: :default
  end

  def perform(scommand, host_ip, host_port)
    return if %w(test development).include? ENV['RAILS_ENV'] ||
      ENV['APPLICATION_HOST'].include?('staging')
    socket = TCPSocket.new host_ip, host_port.to_i
    socket.puts scommand
    socket.close
  end
end

