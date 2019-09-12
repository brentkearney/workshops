# Copyright (c) 2018 Banff International Research Station
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

# Invalid maillist email bounces back to senders
class BounceMailer < ApplicationMailer
  attr_accessor :email_to, :email_from, :email_subject, :email_body,
    :email_date, :webmaster, :subject

  def email_fields(params)
    @email_to = params[:to]
    @email_to = params[:to].join(', ') if params[:to].is_a?(Array)
    @email_from = params[:from]
    @email_subject = params[:subject]
    @email_body = params[:body]
    @email_date = params[:date]
    @webmaster = GetSetting.site_email('webmaster_email')
    @subject = "Bounce notice: #{@email_subject}"
  end

  def invalid_event_code(params)
    email_fields(params)
    mail(to: @email_from, from: @webmaster, subject: @subject)
  end

  def non_member(params)
    email_fields(params)
    @event_code = params[:event_code]
    mail(to: @email_from, from: @webmaster, subject: @subject)
  end

  def unauthorized_subgroup(params)
    email_fields(params)
    @event_code = params[:event_code]
    mail(to: @email_from, from: @webmaster, subject: @subject)
  end
end
