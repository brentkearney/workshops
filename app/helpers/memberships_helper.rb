# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module MembershipsHelper
  def show_roles(f)
    disabled_options = []
    if @current_user.is_organizer?(@event)
      disabled_options = ['Contact Organizer', 'Organizer']
    end

    f.select :role, Membership::ROLES, disabled: disabled_options,
                                       class: 'form-control'
  end

  def show_attendances(f)
    if policy(@membership).edit_attendance?
      disabled_options = []
      if @current_user.is_organizer?(@event)
        if @membership.attendance == 'Not Yet Invited'
          return @membership.attendance
        else
          disabled_options = ['Invited', 'Not Yet Invited']
        end
      end
      f.select :attendance, Membership::ATTENDANCE,
               { include_blank: false, disabled: disabled_options },
               required: 'true', class: 'form-control'
    else
      @membership.attendance
    end
  end

  def show_email(member)
    column = ''
    if policy(@event).view_email_addresses?
      if member.shares_email?
        column = '<td class="hidden-md hidden-lg rowlink-skip" align="middle">' +
          mail_to(member.person.email, '<span class="glyphicon glyphicon-envelope"></span>'.html_safe, :title => "#{member.person.email}", subject: "[#{@event.code}] ") +
          '</td><td class="hidden-xs hidden-sm rowlink-skip">' +
          mail_to(member.person.email, member.person.email, subject: "[#{@event.code}] ") +
          '</td>'
      else
        if policy(@event).use_email_addresses?
          column = '<td class="hidden-md hidden-lg rowlink-skip" align="middle">' +
            mail_to(member.person.email, '<span class="glyphicon glyphicon-lock"></span>'.html_safe, :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td><td class="hidden-xs hidden-sm rowlink-skip">' +
            mail_to(member.person.email, '[not shared]', :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td>'
        else
          column = '<td class="hidden-md hidden-lg rowlink-skip" align="middle">' +
            '<a title="E-mail not shared" class="glyphicon glyphicon-lock"></a></td>' +
            '<td class="hidden-xs hidden-sm rowlink-skip">[not shared]</td>'
        end
      end
    end
    column.html_safe
  end
end
