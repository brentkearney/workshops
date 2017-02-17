# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class ApplicationMailer < ActionMailer::Base
  default from: Setting.Site['application_email']
  layout 'mailer'
end
