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

# Remove attachments from mail logger in debugging mode
module ActionMailer
  class LogSubscriber < ActiveSupport::LogSubscriber
    def deliver(event)
      info do
        recipients = Array(event.payload[:to]).join(', ')
        "Sent mail to #{recipients}, Subject: #{event.payload[:subject]}, on #{Time.now} (#{event.duration.round(1)}ms)"
      end

      debug { remove_attachments(event.payload[:mail]) }
    end

    def remove_attachments(message)
      new_message = ''
      skip = false
      message.each_line do |line|
        new_message << line unless skip
        skip = true if line =~ /Content-Disposition: attachment;/
        skip = false if skip && line =~ /----==_mimepart/
      end
      new_message
    end
  end
end
