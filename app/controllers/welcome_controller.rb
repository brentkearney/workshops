# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class WelcomeController < ApplicationController
  before_action :set_attendance
  before_filter :authenticate_user!

  # GET / or /welcome
  def index
    @memberships = policy_scope(Membership)
    @memberships.delete_if { |m| m.event.start_date < 2.weeks.ago }

    if @memberships.empty?
      redirect_to my_events_path
    else
      @heading = 'Your Current & Upcoming Events'
      @memberships.each { |m| SyncEventMembersJob.perform_later(m.event) if policy(m.event).sync? }
    end
  end

end
