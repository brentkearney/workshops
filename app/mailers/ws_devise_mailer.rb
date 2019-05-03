# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class WsDeviseMailer < Devise::Mailer
  include Devise::Mailers::Helpers
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  @@data = { skip_suppression: true }
  @@workshops = GetSetting.site_email('application_email')

  def confirmation_instructions(record, token, opts={})
    opts[:from] = @@workshops
    opts[:reply_to] = @@workshops
    opts[:sparkpost_data] = @@data
    super
  end

  def reset_password_instructions(record, token, opts={})
    opts[:from] = @@workshops
    opts[:reply_to] = @@workshops
    opts[:sparkpost_data] = @@data
    super
  end

  def unlock_instructions(record, token, opts={})
    opts[:from] = @@workshops
    opts[:reply_to] = @@workshops
    opts[:sparkpost_data] = @@data
    super
  end

  def email_changed(record, opts={})
    opts[:from] = @@workshops
    opts[:reply_to] = @@workshops
    opts[:sparkpost_data] = @@data
    super
  end

  def password_change(record, opts={})
    opts[:from] = @@workshops
    opts[:reply_to] = @@workshops
    opts[:sparkpost_data] = @@data
    super
  end
end
