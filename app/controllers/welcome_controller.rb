# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class WelcomeController < ApplicationController
  before_action :set_attendance, :set_greeting
  before_filter :authenticate_user!

  # GET / or /welcome
  def index
    welcome_page = 'welcome_' + current_user.role + '_path'
    welcome_page.slice!('super_')

    current_user.person.memberships.each do |membership|
      if membership.role =~ /Organizer/ && current_user.member?
        welcome_page = 'welcome_organizers_path'
      end

      # Update user's events with data from remote database
      event = membership.event
      if !event.template
        SyncEventMembersJob.perform_later(event) if policy(event).sync?
      end
    end

    redirect_to send(welcome_page)
  end

  def admin
    @event_heading = 'Current & Upcoming Events'
    @events = Event.where("start_date >= ? AND template=false", 1.week.ago).order(:start_date).limit(8)
    @next_event = Event.where("start_date >= ?", 5.days.ago).order(:start_date).first
    @template_events = Event.select {|e| e.template == true }
  end

  def staff
    @event_heading = 'Current & Upcoming Events at ' + current_user.location
    @events = Event.where("start_date >= ? AND template=false AND location = ?", 1.week.ago, current_user.location).order(:start_date).limit(8)
    @next_event = Event.where("start_date >= ?", Time.now).order(:start_date).first
    @template_events = Event.select {|e| e.template == true && e.location == current_user.location }
  end

  def participants
    @event_heading = 'Your Workshops'
    @events = current_user.person.events.where("template=false AND attendance != 'Not Yet Invited' AND attendance != 'Declined'").order(:start_date)
    @next_event = current_user.person.events.where("template=false AND start_date >= ?", 1.week.ago).order(:start_date).first
  end

  def organizers
    @event_heading = 'Your Workshops'
    @events = current_user.person.events.where("template=false").order(:start_date)
    @next_event = current_user.person.events.where("template=false AND start_date >= ?", 1.week.ago).order(:start_date).first
  end

  private

  def set_greeting
    if current_user
      @heading = greeting + ", #{current_user.person.firstname}!"
    end
  end

  def greeting
    if current_user && current_user.last_sign_in_at
      'Welcome back' if current_user.last_sign_in_at < Time.now
    else
      'Welcome'
    end
  end

end
