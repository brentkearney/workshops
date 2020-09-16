# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives Griddler:Email object, distributes message to destination
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
      subject: subject,
      email_parts: email_parts,
      attachments: @email.attachments,
    }

    if @group == 'orgs' || @group == 'organizers'
      send_to_orgs(message)
    elsif @group == 'all'
      send_to_all(message)
    elsif @group == 'speakers'
      send_to_speakers(message)
    else
      send_to_attendance_group(message)
    end
  end

  def remove_trailing_comma(str)
      str.blank? ? '' : str.chomp(",")
  end

  def send_to_orgs(message)
    to = ''
    @event.contact_organizers.each do |org|
      to << %Q("#{org.name}" <#{org.email}>, )
    end
    to = remove_trailing_comma(to)
    cc = ''
    @event.supporting_organizers.each do |org|
      cc << %Q("#{org.name}" <#{org.email}>, )
    end
    cc = remove_trailing_comma(cc)
    recipients = { to: to, cc: cc }

    if ENV['APPLICATION_HOST'].include?('staging') && @event.code !~ /666/
      recipients = { to: GetSetting.site_email('webmaster_email'), cc: '' }
    end

    begin
      resp = MaillistMailer.workshop_organizers(message, recipients).deliver_now
    rescue
      StaffMailer.notify_sysadmin(@event.id, resp).deliver_now
    end
  end

  def send_to_all(message)
    ['Confirmed', 'Invited', 'Undecided'].each do |status|
      @group = status
      send_to_attendance_group(message)
    end
  end

  def send_to_speakers(message)
    @event.lectures.each do |lecture|
      email_member(lecture.person, message)
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

    begin
      resp = MaillistMailer.workshop_maillist(message, recipient).deliver_now
    rescue
      StaffMailer.notify_sysadmin(@event.id, resp).deliver_now
    end
  end
end
