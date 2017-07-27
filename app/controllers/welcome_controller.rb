# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class WelcomeController < ApplicationController
  before_action :set_attendance, :check_staff
  before_filter :authenticate_user!

  # GET / or /welcome
  def index
    @memberships = policy_scope(Membership)
    @memberships.delete_if {|m| m.event.start_date < 2.weeks.ago }

    if @memberships.empty?
      redirect_to my_events_path
    else
      @heading = 'Your Current & Upcoming Events'
      @memberships.each do |m|
        SyncEventMembersJob.perform_later(m.event_id) if policy(m.event).sync?
      end
    end
  end

  def check_staff
    if current_user && current_user.is_staff?
      redirect_to events_future_path
    end
  end

end
