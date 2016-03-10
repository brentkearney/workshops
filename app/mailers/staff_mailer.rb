# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class StaffMailer < ApplicationMailer
  default from: Global.email.application

  def schedule_change(original, new, changed_similar = false)
    @event = new.event
    to_email = Global.email.locations.send(@event.location).schedule_staff
    subject = "[#{@event.code}] Schedule change notice!"

    @change_notice = %Q(
    THIS:
      Name: #{original.name}
      Start time: #{original.start_time}
      End time: #{original.end_time}
      Location: #{original.location}
      Description: #{original.description}
    
    CHANGED TO:
      Name: #{new.name}
      Start time: #{new.start_time}
      End time: #{new.end_time}
      Location: #{new.location}
      Description: #{new.description}
      Updated by: #{new.updated_by}
    )

    if changed_similar
      @change_notice << %Q(
**** All "#{original.name}" items at #{original.start_time.strftime("%H:%M")} were changed to the new time. ****
      )
    end

    mail(to: to_email, subject: subject, Importance: 'High', 'X-Priority': 1)
  end

  def event_sync(sync_errors)
    @event = sync_errors['Event']
    to_email = Global.email.locations.send(@event.location).program_coordinator
    cc_email = Global.email.system_administrator
    subject = "!! #{@event.code} (#{@event.location}) Data errors !!"

    @error_messages = ''

    sync_errors['People'].each do |person|
      person_name = "#{person[:lastname]}, #{person[:firstname]}"
      legacy_url = Global.config.legacy_person

      if person.legacy_id.nil?
        message = "During #{@event.code} data synchronization, we found a local person record with no legacy_id:\n\n"
        message << "#{person.inspect}"
        StaffMailer.notify_sysadmin(@event, message).deliver_now
      else
        legacy_url += "#{person.legacy_id}"
      end

      person.valid?
      person_errors = person.errors.full_messages
      @error_messages << "#{person_name}: #{person_errors}\n"
      @error_messages << "   * #{legacy_url}\n\n"
    end

    sync_errors['Memberships'].each do |membership|
      person_name = membership.person.name
      legacy_url = Global.config.legacy_person
      unless membership.person.legacy_id.nil?
        legacy_url += "#{membership.person.legacy_id}" + '&ps=events'
      end

      membership.valid?
      membership_errors = membership.errors.full_messages
      membership_errors.each do |error|
        unless error.start_with?('Person')
          @error_messages << "Error in #{person_name}'s #{@event_code} membership: #{error}\n"
          @error_messages << "   * #{legacy_url}\n\n"
        end
      end
    end

    mail(to: to_email, cc: cc_email, subject: subject)
  end

  def notify_sysadmin(event, message)
    to_email = Global.email.system_administrator
    subject = "[#{event.code}] (#{event.location}) Data errors !!"
    @message = message
    mail(to: to_email, subject: subject, Importance: 'High', 'X-Priority': 1, template_name: 'notify_sysadmin')
  end

end
