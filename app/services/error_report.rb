# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.


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

    unless error.blank?
      if errors.has_key?(objects)
        errors["#{objects}"] << error
      else
        errors["#{objects}"] = [error]
      end
    end
  end

  def send_report
    return if errors.empty?

    case "#{@from}"
      when 'SyncMembers'
        if errors.has_key?('LegacyConnector')
          error = errors['LegacyConnector'].shift
          StaffMailer.notify_sysadmin(@event, error).deliver_now
        end

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
    the_object.valid? if the_object.is_a?(ActiveRecord::Base)
    message = error_message.nil? ? the_object.errors.full_messages : error_message
    Error.new(the_object, message) unless message.blank?
  end
end
