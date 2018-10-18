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

# Sends mail to workshop participants, like a maillist
class MaillistMailer < ApplicationMailer
  def workshop_maillist(message, recipient)
    location = message[:location]
    from = GetSetting.email(location, 'maillist_from')
    subject = message[:subject]
    email_parts = message[:email_parts]
    text_body = email_parts[:text_body]
    html_body = email_parts[:html_body]
    inline_attachments = email_parts[:inline_attachments]

    unless message[:attachments].blank?
      message[:attachments].each do |ad|
        file = ad.original_filename
        if inline_attachments[file] != nil
          attachments.inline[file] = {
            mime_type: ad.content_type,
            content: File.read(ad.tempfile)
          }
          attachments.inline[file].header['content-id'] = inline_attachments[file]
        else
          attachments[file] = {
            mime_type: ad.content_type,
            content: File.read(ad.tempfile)
          }
        end
      end
    end

    mail(to: recipient, from: from, subject: subject) do |format|
      format.html { render html: html_body.html_safe } unless html_body.blank?
      format.text { render text: text_body }
    end
  end
end
