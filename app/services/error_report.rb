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
    objects = 'LegacyConnector' if objects == 'FakeLegacyConnector' # for rspec
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
    return if errors.blank?

    case "#{@from}"
      when 'SyncMembers'
        return if errors.blank?
        if errors.has_key?('LegacyConnector')
          error = errors['LegacyConnector'].shift
          return if error.blank?
          error_message = "Error message:\n"
          unless error.object.nil?
            error_message << error.object.inspect.to_s
          else
            error_message << error.inspect
          end
          error_message << "\n\n" + error.message

          StaffMailer.notify_sysadmin(@event, error_message).deliver_now
        end

        error_messages = ''
        # Errors in 'Person' records
        if errors.has_key?('Person')
          errors['Person'].each do |person_error|
            person = person_error.object
            message = person_error.message.to_s
            legacy_url = Setting.Site['legacy_person']

            if person.legacy_id.nil?
              error_messages << "\n\nDuring #{event.code} data synchronization,
               a local person record with no legacy_id was found!
               #{person.inspect}\n\n".squish
            else
              legacy_url += "#{person.legacy_id}"
            end

            error_messages << "* #{person.name}: #{message}\n"
            error_messages << "   -> #{legacy_url}\n\n"
          end
        end

        # Errors in 'Membership' records
        if errors.has_key?('Membership')
          errors['Membership'].each do |error_obj|
            membership = error_obj.object
            message = error_obj.message.to_s

            unless duplicate_error(membership.person, message)
              error_messages << "\nMembership error: #{message}\n"
              if membership.person.nil?
                error_messages << "* #{@event.code} membership has no associated
                  person record!\n\n#{membership.inspect}\n"
              else
                error_messages << "\n\n* Membership of #{membership.person.name}:\n   --> "
                error_messages << 'https://' + ENV['APPLICATION_HOST'] + "/events/#{@event.code}"
                error_messages << "/memberships/#{membership.id}\n\n"
              end
            end
          end
        end

        if errors.has_key?('Event')
          error_messages = errors['Event'].first.message.to_s
          membership_url = GetSetting.app_url + '/events/' + @event.code + '/memberships'
          error_messages << "\n" + membership_url
        end

        unless error_messages.blank?
          StaffMailer.event_sync(@event, error_messages).deliver_now
        end
      else
        # Iterate over Errors hash, send report for each type of error
        errors.each do |string, array|
          error_message = errors[string].shift.message
          error_message << "\n and: #{array.inspect}"
          unless error_message.blank?
            StaffMailer.notify_sysadmin(@event, error_message).deliver_now
          end
        end
    end
  end

  def duplicate_error(obj, message)
    if errors.has_key?("#{obj.class}")
      errors["#{obj.class}"].each do |item|
        if item.object == obj
          if item.message.to_s.downcase == message.gsub(/Person\ /, '')
            return true
          else
            return false
          end
        end
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
