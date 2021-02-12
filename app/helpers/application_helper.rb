# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module ApplicationHelper
  def devise_error_messages
    return '' if !defined?(resource) || resource.nil?
    return '' unless resource.errors.present?
    messages = resource.errors.full_messages.join('，')
    sentence = I18n.t('errors.messages.not_saved',
                      count: resource.errors.count,
                      resource: resource.class.model_name.human.downcase)
    "#{sentence}#{messages}"
  end

  def page_title
    case request.path
    when events_future_path
      'Future Events'
    when events_past_path
      'Past Events'
    when /(future|past)\/location\/(\w+)\z/
      %Q(#{@tense} #{@location} Events)
    when /events\/year\/(\d{4})/
      %Q(#{@year} Events)
    when /year\/(\d{4})\/location/
      %Q(#{@year} #{@location} Events)
    when /events\/(\w+)\/schedule/
      %Q(#{@event.code} Schedule)
    when /events\/(\w+)\/memberships/
      %Q(#{@event.code} Members)
    when /sign_in/
      "Workshops Sign-in"
    when /register/
      "Workshops Registration"
    when /invitations/
      "Workshop Invitations"
    else
      return %Q(#{@event.code}: #{@event.name}) unless @event.nil?
      Setting.Site[:title]
    end
  end

  def sidebar_toggle
    cookies[:sidebar_toggle] == 'true' ? 'sidenav-toggled' : ''
  end

  def profile_pic(person)
    image_tag "profile.png", alt: "#{person.name}", id: "profile-pic-#{person.id}", class: "img-responsive img-rounded"
  end

  def user_is_staff?
    current_user && current_user.is_staff?
  end

  def user_is_organizer?
    current_user && current_user.is_organizer?(@event)
  end

  def user_is_member?
    current_user && current_user.is_member?(@event)
  end

  def display_new_feature_notice?
    return if current_user.nil?
    return if cookies[:read_notice2]
    current_user.sign_in_count > 1 && Date.current < Date.parse('2020-06-30')
  end

  def set_read_notice
    cookies[:read_notice2] = { value: true, expires: 1.month.from_now }
  end

  def pluralize_no_count(count, singular, plural = nil)
    ((count == 1 || count == '1') ? singular : (plural || singular.pluralize))
  end
end
