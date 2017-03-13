# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class ApplicationMailer < ActionMailer::Base
  app_email = Setting.Site['application_email'] unless Setting.Site.blank?
  if Setting.Site.blank? || app_email.nil?
    app_email = ENV['DEVISE_EMAIL']
  end
  default from: app_email
  layout 'mailer'
end
