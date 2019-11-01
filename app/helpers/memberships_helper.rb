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

    f.select :role, Membership::ROLES,
             { disabled: disabled_options, selected: default },
             class: 'form-control'
  end

  def add_member_errors(add_members)
    return '' if add_members.errors.empty?
    errors = add_members.errors
    msg = "<p><strong>‼️These problems were detected:</strong>\n"
    msg << "<ol id=\"add-members-errors\">\n"
    errors.messages.each do |line|
      msg << "<li value=\"#{line[0]}\">"
      line[1].each do |prob|
        msg << "#{prob}, "
      end
      msg.chomp!(', ') << ".</li>\n"
    end
    msg << "</ol>\n"

    msg << '</p>'
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

  def show_invited_by?
    invited_by = ''
    if @membership.attendance == 'Invited'
      unless @membership.invited_by.blank?
        invited_by='
        <div class="row" id="profile-rsvp-invited">
          Invited by: ' + @membership.invited_by
        unless @membership.invited_on.blank?
          invited_by << ' on '
          invited_by << @membership.invited_on.in_time_zone(@membership.event.time_zone).to_s
        end
        invited_by << '</div>'
      end
    end
    invited_by.html_safe
  end

  def parse_reminders(rhash)
    text = '<ul>'
    rhash.each {|k,v| text << "<li>On #{k.strftime('%Y-%m-%d %H:%M %Z')}<br>by #{v}</li>"}
    text << '</ul>'
  end

  def show_invited_on_date(member)
    column = '<td class="rowlink-skip no-print hidden-xs hidden-sm">'
    if show_invited_on?(member)
      if member.invited_on.blank?
        column << '(not set)'
      else
        column << '(' +
          member.invited_on.strftime('%Y-%m-%d') + ')'
      end
      unless member.invite_reminders.blank?
        column << ' <span id="reminders-icon"><a tabindex="0" title="Reminders Sent" role="button" data-toggle="popover" data-html="true" data-target="#reminders-' + member.id.to_s + '" data-trigger="hover focus" data-content="' + parse_reminders(member.invite_reminders) + '"><span class="glyphicon glyphicon-repeat"></span></a></span>'.html_safe
      end
    end
    column << '</td>'
    column.html_safe
  end

  def show_invited_on?(member)
    policy(@event).send_invitations? &&
      %w(Invited Undecided).include?(member.attendance)
  end

  def add_email_buttons(status)
    return unless policy(@event).show_email_buttons?(status)
    content = '<div class="no-print" id="email-members">'
    content << add_email_button(status)
    content << "\n</div>\n"
    content.html_safe
  end

  def invite_button(status)
    return 'Invite Selected Members' if status == 'Not Yet Invited'
    "Send Reminder to Selected #{status.titleize} Members"
  end

  def spots_left
    @event.max_participants - @event.num_invited_participants > 0
  end

  def add_email_button(status)
    return '' unless policy(@event).show_email_buttons?(status)
    to_email = "#{@event.code}-#{status.parameterize(separator: '_')}@#{@domain}"
    to_email = "#{@event.code}@#{@domain}" if status == 'Confirmed'
    content = mail_to(to_email, "<i class=\"fa fa-envelope fa-fw\"></i> Email #{status} Members".html_safe, subject: "[#{@event.code}] ", title: "Email #{to_email}", class: 'btn btn-sm btn-default email-members')

    if status == 'Confirmed' && !@organizer_emails.blank?
      content << ' | '
      content << mail_to(@organizer_emails.join(','), "<i class=\"fa fa-envelope fa-fw\"></i> Email Organizers".html_safe, subject: "[#{@event.code}] ", class: 'btn btn-sm btn-default email-members')
    end
    content
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

  def add_limits_message(status)
    return unless status == 'Not Yet Invited'
    spots = @event.max_participants - @event.num_invited_participants
    isare = 'are'
    isare = 'is' if spots == 1
    spot_s = 'spots'
    spot_s = 'spot' if spots == 1
    unless_cancel = ''
    if spots == 0
      unless_cancel = 'Unless someone cancels, no more invitations can be sent.'
    end
    ('<div class="no-print" id="limits-message">There ' + "#{isare} #{spots} #{spot_s} left,
      out of a maximum of #{@event.max_participants}. #{unless_cancel}</div>").squish.html_safe
  end

  def display_new_feature_notice?
    @unread_notice && @current_user.sign_in_count > 1 &&
      Date.current < Date.parse('2019-11-30') && policy(@event).send_invitations?
  end
end
