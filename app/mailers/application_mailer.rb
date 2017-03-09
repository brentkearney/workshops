# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class ApplicationMailer < ActionMailer::Base
  app_email = Setting.Site['application_email']
  app_email = 'workshops@example.com' if app_email.nil?
  default from: app_email
  layout 'mailer'
end
