# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Collects error data and emails them to staff
class ErrorReport
  attr_reader :errors_from, :errors

  def initialize(errors_from)
    @errors_from = errors_from
    @errors = {}
    # @sync_errors = { 'Event' => @event, 'People' => Array.new, 'Memberships' => Array.new }
  end

  def add(the_object, error_message = nil)
    objects = "#{the_object.class}"
    error = errorify(the_object, error_message)

    if errors.has_key?(objects)
      errors["#{objects}"] << error
    else
      errors["#{objects}"] = [error]
    end
  end

  def send_report
    StaffMailer.event_sync(errors).deliver_now unless errors.empty?
  end

  Error = Struct.new(:object, :message)
  def errorify(the_object, error_message)
    Error.new(the_object, error_message.nil? ? the_object.errors.full_messages : error_message)
  end
end
