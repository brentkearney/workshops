# app/mailers/confirm_email_mailer.rb
# Copyright (c) 2019 Banff International Research Station
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

# Notification messages to Staff
class ConfirmEmailMailer < ApplicationMailer
  app_email = GetSetting.site_email('webmaster_email')
  default from: app_email

  def send_msg(confirm_id, mode: 'replace')
    confirm = ConfirmEmailChange.find(confirm_id)
    @replace_email = confirm.replace_email
    @replace_with_email = confirm.replace_with_email

    person_id = mode == 'replace' ? 'replace_person_id' : 'replace_with_id'
    @person = Person.find("#{confirm.send(person_id)}")
    @verification_code = confirm.send(mode + '_code')

    to_email = %Q("#{@person.name}" <#{@person.email}>)
    subject = "BIRS email change confirmation"

    mail(to: to_email, subject: subject, template_name: mode)
  end
end
