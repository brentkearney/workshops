# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class HomeController < ApplicationController
  before_action :set_attendance
  before_action :authenticate_user!

  # GET / or /home
  def index
    if staff_at_location?
      redirect_to events_future_path(current_user.location) and return
    end

    @memberships = policy_scope(Membership)
    @memberships.delete_if {|m| m.event.start_date < 2.weeks.ago }

    if @memberships.empty?
      redirect_to events_future_path
    else
      @heading = 'Your Current & Upcoming Events'
      @memberships.each do |m|
        SyncEventMembersJob.perform_later(m.event_id) if policy(m.event).sync?
      end
    end
  end

  def staff_at_location?
    current_user && current_user.staff? && !current_user.location.blank?
  end
end
