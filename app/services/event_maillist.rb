# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives Griddler:Email object, distributes message to confirmed members
class EventMaillist
  def initialize(email, mailist_params)
    @email       = email
    @event       = mailist_params[:event]
    @group       = mailist_params[:group]
    @destination = mailist_params[:destination]
  end

  def send_message
    subject = @email.subject
    subject = "[#{@event.code}] #{subject}" unless subject.include?(@event.code)
    email_parts = EmailParser.new(@email, @destination, @event).parse

    message = {
      location: @event.location,
      from: @email.from[:full],
      to: @email.to[0][:full],
      subject: @email.subject,
      email_parts: email_parts,
      attachments: @email.attachments,
    }

    if @group == 'orgs' || @group == 'organizers'
      send_to_orgs(message)
    elsif @group == 'all'
      send_to_all(message)
    else
      send_to_attendance_group(message)
    end
  end

  def send_to_orgs(message)
    @event.organizers.each do |member|
      email_member(member, message)
    end
  end

  def send_to_all(message)
    ['Confirmed', 'Invited', 'Undecided'].each do |status|
      @group = status
      send_to_attendance_group(message)
    end
  end

  def send_to_attendance_group(message)
    if @group == 'Not Yet Invited'
      members = @event.attendance(@group) - @event.role('Backup Participant')
      members.each do |member|
        email_member(member, message)
      end
    else
      @event.attendance(@group).each do |member|
        email_member(member, message)
      end
    end
  end

  def email_member(member, message)
    if member.is_a?(Person)
      recipient = %Q("#{member.name}" <#{member.email}>)
    else
      recipient = %Q("#{member.person.name}" <#{member.person.email}>)
    end

    if ENV['APPLICATION_HOST'].include?('staging') && @event.code !~ /666/
      recipient = GetSetting.site_email('webmaster_email')
    end

    resp = MaillistMailer.workshop_maillist(message, recipient).deliver_now!

    if !resp.nil? && resp['total_rejected_recipients'] != 0
      StaffMailer.notify_sysadmin(@event.id, resp).deliver_now
    end
  end
end
