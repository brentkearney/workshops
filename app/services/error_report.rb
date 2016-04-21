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
  attr_reader :from, :event, :errors

  def initialize(errors_from, event)
    @from = errors_from
    @event = event
    @errors = {}
  end

  def add(the_object, error_message = nil)
    objects = "#{the_object.class}"
    objects = 'LegacyConnector' if objects == 'FakeLegacyConnector' # for rspec tests
    error = errorify(the_object, error_message)

    if errors.has_key?(objects)
      errors["#{objects}"] << error
    else
      errors["#{objects}"] = [error]
    end
  end

  def send_report
    return if errors.empty?
    case "#{@from}"
      when 'SyncMembers'
        if errors.has_key?('LegacyConnector')
          error = errors['LegacyConnector'].shift
          StaffMailer.notify_sysadmin(@event, error).deliver_now
        else
          error_messages = ''
          # Errors in 'Person' records
          if errors.has_key?('Person')
            errors['Person'].each do |person_error|
              person = person_error.object
              message = person_error.message.to_s
              legacy_url = Global.config.legacy_person

              if person.legacy_id.nil?
                person_error.message << "\n\nDuring #{event.code} data synchronization, we found a local person record with no legacy_id!\n\n"
                StaffMailer.notify_sysadmin(event, person_error).deliver_now
              else
                legacy_url += "#{person.legacy_id}"
              end

              error_messages << "* #{person.name}: #{message}\n"
              error_messages << "   -> #{legacy_url}\n\n"
            end
          end

          # Errors in 'Membership' records
          if errors.has_key?('Membership')
            errors['Membership'].each do |membership_error|
              membership = membership_error.object
              message = membership_error.message.to_s

              unless message.start_with?('["Person')
                legacy_url = Global.config.legacy_person + "#{membership.person.legacy_id}" + '&ps=events'
                error_messages << "* Membership of #{membership.person.name}: #{message}\n"
                error_messages << "   -> #{legacy_url}\n\n"
              end
            end
          end

          StaffMailer.event_sync(@event, error_messages).deliver_now
        end
    end
  end

  Error = Struct.new(:object, :message)
  def errorify(the_object, error_message)
    Error.new(the_object, error_message.nil? ? the_object.errors.full_messages : error_message)
  end
end
