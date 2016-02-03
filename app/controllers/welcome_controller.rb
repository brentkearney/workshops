# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class WelcomeController < ApplicationController
  before_action :set_attendance
  before_filter :authenticate_user!

  # GET / or /welcome
  def index
    @memberships = current_user.person.memberships.includes(:event).sort_by {|m| m.event.start_date }
    @memberships.delete_if {|m| (m.role !~ /Organizer/ && m.attendance == 'Declined') ||
        m.role == 'Backup Participant' || m.attendance == 'Not Yet Invited' ||
        m.event.start_date < 2.weeks.ago
    }

    if @memberships.empty?
      redirect_to my_events_path
    else
      prefix = current_user.last_sign_in_at.nil? ? 'Welcome' : 'Welcome back'
      @heading = "#{prefix}, #{current_user.person.firstname}!"

      @memberships.each do |m|
        # Update user's events with data from remote database.
        unless m.event.template
          SyncEventMembersJob.perform_later(m.event) if policy(m.event).sync?
        end
      end
    end
  end

end
