# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class InvitationMailer < ApplicationMailer
  app_email = Setting.Site['application_email'] unless Setting.Site.blank?
  if Setting.Site.blank? || app_email.nil?
    app_email = ENV['DEVISE_EMAIL']
  end

  default from: app_email

  def invite(invitation)
    @person = invitation.person
    @event = invitation.membership.event
    @rsvp_link = Setting.Site['app_url'] + '/rsvp/' + invitation.code
    @org_name = Setting.Locations["#{@event.location}"]['Name']
    @event_url = Setting.Site['events_url'] + @event.code
    subject = "[#{@event.code}] Your invitation to \"#{@event.name}\""

    mail(to: @person.email, subject: subject, Importance: 'High', 'X-Priority': 1)
  end

end
