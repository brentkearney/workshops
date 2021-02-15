# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Helpers for memberships
module MembershipsHelper

  def pending_invitation?
    @current_user.person == @membership.person && !@membership.invitation.nil?
  end

  def event_membership_name(m)
    m.event.code + ': ' + m.event.name + ' (' + m.event.date + ')'
  end

  def date_list
    start_date = @event.start_date
    end_date = @event.end_date
    if policy(@membership).extended_stay?
      start_date -= 7.days
      end_date += 7.days
    end
    dates = [start_date]
    dates << dates.last + 1.day while dates.last != end_date
    dates
  end

  def selected_date(type = nil)
    if type == 'arrival'
      return @membership.arrival_date unless @membership.arrival_date.nil?
      return @event.start_date
    else
      return @membership.departure_date unless @membership.departure_date.nil?
      return @event.end_date
    end
  end

  def show_roles(f, default: nil)
    disabled_options = []
    if @current_user.is_organizer?(@event) && !@current_user.is_admin?
      disabled_options = ['Contact Organizer', 'Organizer']
    end
    disabled_options << 'Participant' if @event.online?
    disabled_options << 'Virtual Participant' if @event.physical?


    f.select :role, Membership::ROLES,
             { selected: default, disabled: disabled_options },
             class: 'form-control'
  end

  def add_member_errors(add_members)
    return '' if add_members.errors.empty?
    errors = add_members.errors
    msg = "<h3>‼️Problems were detected on these lines, below:</h3>\n"
    msg << "<ol id=\"add-members-errors\">\n"
    errors.messages.each do |line|
      msg << "<li value=\"#{line[0]}\">"
      line[1].each do |prob|
        msg << "#{prob}, "
      end
      msg.chomp!(', ') << ".</li>\n"
    end
    msg << "</ol>\n"
  end

  def invalid_email?(add_members, line)
    if add_members.errors.messages[:"#{line}"].first.include?("E-mail")
      return 'has-error'
    end
  end

  def show_attendances(f)
    if policy(@membership).edit_attendance?
      f.select :attendance, policy(@membership).attendance_options,
                { selected: @membership.attendance }, class: 'form-control'
    else
      @membership.attendance
    end
  end

  def print_section?(section)
    return ' no-print' unless section == 'Confirmed'
  end

  def invite_title(status)
    title = 'Send '
    title << (status == 'Not Yet Invited' ? 'Invitations ' : 'Reminders ')
    title << 'to ' + status + ' Members'
  end

  def format_invited_by(membership)
    invited_by=''
    unless membership.invited_by.blank?
      invited_by = membership.invited_by
      unless membership.invited_on.blank?
        invited_by << ' on <br>'
        tz = membership.event.time_zone
        invited_by << membership.invited_on.in_time_zone(tz).to_s
      end
    end
    invited_by
  end

  def show_invited_by?
    invited_by = ''
    unless ['Confirmed', 'Not Yet Invited'].include? @membership.attendance
      invited_by = '<div class="row" id="profile-rsvp-invited">Invited by: '
      invited_by << format_invited_by(@membership)
      invited_by << '</div>'
    end
    invited_by.html_safe
  end

  def rsvp_by(event, invited_on)
    rsvp_by = RsvpDeadline.new(event, invited_on).rsvp_by
    DateTime.parse(rsvp_by).strftime('%b. %e, %Y')
  end

  def parse_reminders(member)
    text = '<ul>'
    member.invite_reminders.each do |k,v|
      text << "<li><b>On #{k.strftime('%Y-%m-%d %H:%M %Z')}</b><br>by #{v}.</li>"
    end
    text << '</ul>'
  end

  def last_invited(member, tz)
    unless member.invite_reminders.blank?
      return member.invite_reminders.keys.last.in_time_zone(tz)
    end
    if member.invited_on.blank?
      DateTime.current.in_time_zone(tz)
    else
      member.invited_on.in_time_zone(tz)
    end
  end

  def show_reply_by_date(member)
    invited_on = last_invited(member, member.event.time_zone)
    DateTime.parse(rsvp_by(member.event, invited_on)).strftime("%Y-%m-%d")
  end

  def show_invited_on_date(member, no_td = false)
    column = no_td ? '' : '<td class="rowlink-skip no-print">'
    return unless show_invited_on?(member.attendance)
    if member.invited_on.blank?
      column << '(not set)'
    else
      invited_on = member.invited_on.in_time_zone(member.event.time_zone)
      column << '<a class="invitation-dates" tabindex="0" title="Invitation Sent"
        role="button" data-toggle="popover" data-placement="top" data-html="true"
        data-target="#invitations-' + member.id.to_s + '"
        data-trigger="hover focus" data-content="By ' +
        format_invited_by(member) + '<br><b>Reply-by date:</b> ' +
        rsvp_by(member.event, invited_on) +
        '" >'+ member.invited_on.strftime("%Y-%m-%d") +'</a>'
    end
    unless member.invite_reminders.blank?
      column << ' <span id="reminders-icon"><a tabindex="0" title="Reminders Sent" role="button" data-toggle="popover" data-html="true" data-target="#reminders-' + member.id.to_s + '" data-trigger="hover focus" data-content="' + parse_reminders(member) + '"> &nbsp; <i class="fa fa-md fa-repeat"></i></a></span>'.html_safe
    end

    column << "#{no_td ? '' : '</td>'}"
    column.html_safe
  end

  def show_invited_on?(status)
    %w(Invited Undecided).include?(status) && policy(@event).send_invitations?
  end

  def latest_request_date(member)
    tz = member.event.time_zone

    if member.invite_reminders.blank?
      rsvp_by_date = member.invited_on.in_time_zone(tz)
    else
      rsvp_by_date = member.invite_reminders.keys.last.in_time_zone(tz)
    end

    RsvpDeadline.new(member.event, rsvp_by_date).rsvp_by
  end

  def reply_due?(member)
    return '' unless show_invited_on?(member.attendance)
    return '' if member.invited_on.blank?

    rsvp_by = latest_request_date(member)
    return 'reply-due' if DateTime.current > DateTime.parse(rsvp_by)
  end

  def old_add_email_buttons(status)
    return unless policy(@event).show_email_buttons?(status)
    content = '<div class="no-print" id="email-members">'
    content << add_email_button(status)
    content << "\n</div>\n"
    content.html_safe
  end

  def invite_button(status, smallscreen = false)
    return 'Invite Selected Members' if status == 'Not Yet Invited'
    return 'Send Reminders to Selected' if smallscreen
    "Send Reminder to Selected #{status.titleize} Members"
  end

  def spots_left
    @event.max_participants - @event.num_invited_participants > 0
  end



  def add_email_buttons(status)
    return '' unless policy(@event).show_email_buttons?(status)
    domain = GetSetting.email(@event.location, 'email_domain')
    to_email = "#{@event.code}-#{status.parameterize(separator: '_')}@#{domain}"
    to_email = "#{@event.code}@#{domain}" if status == 'Confirmed'

    content = mail_to(to_email, to_email, subject: "[#{@event.code}] ", title: "Email #{status} members at #{to_email}")

    if status == 'Confirmed'
      content << ' <span class="separator">|</span> '.html_safe
      content << mail_to("#{@event.code}-organizers@#{domain}", "#{@event.code}-organizers@#{domain}", title: "Email event organizers", subject: "[#{@event.code}] ").html_safe
    end
    content.html_safe
  end

  def show_email(member)
    column = ''
    if policy(member).show_email_address?
      column = '<td class="hidden-md hidden-lg rowlink-skip no-print" align="middle">' +
        mail_to(member.person.email, '<span class="glyphicon glyphicon-envelope"></span>'.html_safe,
          title: "#{member.person.email}", subject: "[#{@event.code}] ") +
          '</td><td class="hidden-xs hidden-sm rowlink-skip no-print">' +
          mail_to(member.person.email, member.person.email, subject: "[#{@event.code}] ") +
          '</td>'
    elsif policy(member).use_email_addresses?
          column = '<td class="hidden-md hidden-lg rowlink-skip no-print" align="middle">' +
            mail_to(member.person.email, '<span class="glyphicon glyphicon-lock"></span>'.html_safe, :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td><td class="hidden-xs hidden-sm rowlink-skip no-print">' +
            mail_to(member.person.email, '[not shared]', title: "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td>'
    elsif policy(member).show_not_shared?
      column = '<td class="hidden-md hidden-lg rowlink-skip no-print" align="middle">' +
        '<a title="E-mail not shared" class="glyphicon glyphicon-lock"></a></td>' +
        '<td class="hidden-xs hidden-sm rowlink-skip">[not shared]</td>'
    end
    column.html_safe
  end

  def cancellations_msg(physical_spots, virtual_spots)
    if physical_spots == 0
      return "<br>\nUnless there are cancellations from in-person participants,
        no more can be invited."
    end

    if virtual_spots == 0
      return "<br>\nUnless there are cancellations from virtual participants,
        no more can be invited."
    end

    ''
  end

  def hybrid_spots_msg
    max_physical = @event.max_participants
    physical_spots = max_physical - @event.num_invited_in_person
    max_virtual = @event.max_virtual
    virtual_spots = max_virtual - @event.num_invited_virtual

    msg = "There #{pluralize_no_count(physical_spots, 'is', 'are')}
      <strong>#{physical_spots}/#{max_physical}</strong>
      #{pluralize_no_count(physical_spots, 'in-person spot')}, and
      <strong>#{virtual_spots}/#{max_virtual}</strong>
      #{pluralize_no_count(virtual_spots, 'virtual spot')} left
      (includes confirmed + invited)."

    msg << cancellations_msg(physical_spots, virtual_spots)
  end

  def compose_spots_left_msg(format)
    return hybrid_spots_msg if format == 'Hybrid'

    max = format == 'Online' ? @event.max_virtual : @event.max_participants
    invited = @event.num_invited_participants
    spots = max - invited

    msg = "There #{pluralize_no_count(spots, 'is', 'are')}
      #{pluralize(spots, 'spot')} left: #{invited} confirmed & invited /
      #{max} maximum."

    if spots == 0
      msg << "<br>\nUnless there are cancellations, no more can be invited."
    end

    msg
  end

  def add_limits_message
    (%Q{<div class="no-print" id="limits-message">
      #{compose_spots_left_msg(@event.event_format)}</div>}).squish.html_safe
  end

  def get_status_heading(status)
    case status
    when "Confirmed"
      '<i class="fa fa-check-circle-o" aria-hidden="true"></i> Confirmed'
    when "Invited"
      '<i class="fa fa-envelope-o" aria-hidden="true"></i> Invited'
    when "Undecided"
      '<i class="fa fa-envelope-open-o" aria-hidden="true"></i> Undecided'
    when "Not Yet Invited"
      '<i class="fa fa-clock-o" aria-hidden="true"></i> Not Yet Invited'
    when "Declined"
      '<i class="fa fa-times-circle-o" aria-hidden="true"></i> Declined'
    else
      status
    end
  end

  def status_with_icon(status)
    get_status_heading(status).html_safe
  end

  def add_member_icons(member, line)
    case member.role
    when "Contact Organizer"
      line.prepend('<i class="fa fa-star" aria-hidden="true"></i> '
          .html_safe)
    when /Organizer/
      line.prepend('<i class="fa fa-star-half-o" aria-hidden="true"></i> '
          .html_safe)
    when /Virtual/
      return line if member.event.event_format == 'Online'
      line.prepend('<i class="fa fa-video-camera" aria-hidden="true"></i> '
          .html_safe)
    when /Backup/
      line.prepend('<i class="fa fa-clock-o" aria-hidden="true"></i> '
          .html_safe)
    end

    line
  end

  def show_member(member)
    line = '<span class="' + member.role.parameterize + '">'
    line << member_link(member)
    line << '</span>'

    unless member.person.affiliation.blank?
      line << " (#{member.person.affiliation})"
    end

    add_member_icons(member, line).html_safe
  end

  def member_link(member)
    link_to "#{member.person.lname}", event_membership_path(@event, member)
  end

  def show_guests(member)
    return 'No' unless member.has_guest
    member.num_guests
  end

  def rsvp_setting(setting, location = @event.location)
    intro = GetSetting.send(setting, location)
    return '' if intro.blank?
    intro.html_safe
  end
end
