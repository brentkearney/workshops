# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Helpers for memberships
module MembershipsHelper
  def event_membership_name(m)
    m.event.code + ': ' + m.event.name + ' (' + m.event.date + ')'
  end

  def date_list
    start_date = @event.start_date
    end_date = @event.end_date
    if policy(@membership).allow_extended_stays?
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

  def show_roles(f)
    disabled_options = []
    if @current_user.is_organizer?(@event)
      disabled_options = ['Contact Organizer', 'Organizer']
    end

    f.select :role, Membership::ROLES,
             { include_blank: false, disabled: disabled_options },
             required: 'true', class: 'form-control'
  end

  def show_attendances(f)
    if policy(@membership).edit_attendance?
      disabled_options = Membership::ATTENDANCE
      if @current_user.is_organizer?(@event)
        if @membership.attendance =~ /Invited|Undecided/
          disabled_options -= ['Declined']
        elsif @membership.attendance == 'Confirmed'
          disabled_options -= ['Undecided', 'Declined']
        end
      else
        disabled_options = [] unless @current_user.member?
      end
      f.select :attendance, Membership::ATTENDANCE,
               { include_blank: false, disabled: disabled_options },
                 required: 'true', class: 'form-control'
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
          Invited by: ' + @membership.invited_by + ' on ' +
          @membership.invited_on.to_s + '
        </div>
        '
      end
    end
    invited_by.html_safe
  end

  def show_invite_buttons?(member)
    policy(member).send_invitations? && member.attendance == 'Not Yet Invited'
  end

  def show_reinvite_buttons?(member)
    policy(member).send_invitations? &&
      (member.attendance == 'Invited' || member.attendance == 'Undecided')
  end

  def show_invite_button(member)
    return unless show_invite_buttons?(member)
    column = '<td class="rowlink-skip no-print">' +
      link_to("Send Invitation", invitations_send_path(member),
        data: { confirm: "This will send #{member.person.name}
        an email, inviting #{member.person.him} to attend this
        workshop. Are you sure you want to proceed?".squish },
        class: 'btn btn-sm btn-default') + '</td>'
    column.html_safe
  end

  def show_reinvite_button(member)
    return unless show_reinvite_buttons?(member)
    column = '<td class="rowlink-skip no-print">' +
      link_to("Resend Invitation", invitations_send_path(member),
        data: { confirm: "This will send #{member.person.name}
        an email, re-inviting #{member.person.him} to attend this
        workshop. Are you sure you want to proceed?".squish },
        class: 'btn btn-sm btn-default') + '</td>'
    column.html_safe
  end

  def show_email(member)
    column = ''
    if policy(@event).view_email_addresses?
      if member.shares_email?
        column = '<td class="hidden-md hidden-lg rowlink-skip no-print" align="middle">' +
          mail_to(member.person.email, '<span class="glyphicon glyphicon-envelope"></span>'.html_safe, :title => "#{member.person.email}", subject: "[#{@event.code}] ") +
          '</td><td class="hidden-xs hidden-sm rowlink-skip no-print">' +
          mail_to(member.person.email, member.person.email, subject: "[#{@event.code}] ") +
          '</td>'
      else
        if policy(@event).use_email_addresses?
          column = '<td class="hidden-md hidden-lg rowlink-skip no-print" align="middle">' +
            mail_to(member.person.email, '<span class="glyphicon glyphicon-lock"></span>'.html_safe, :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td><td class="hidden-xs hidden-sm rowlink-skip no-print">' +
            mail_to(member.person.email, '[not shared]', :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td>'
        else
          column = '<td class="hidden-md hidden-lg rowlink-skip no-print" align="middle">' +
            '<a title="E-mail not shared" class="glyphicon glyphicon-lock"></a></td>' +
            '<td class="hidden-xs hidden-sm rowlink-skip">[not shared]</td>'
        end
      end
    end
    column.html_safe
  end
end
