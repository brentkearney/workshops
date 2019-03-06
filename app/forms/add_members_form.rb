# app/forms/add_members_form.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/add.html.erb
class AddMembersForm < ComplexForms
  attr_accessor :added, :new_people, :role, :sync_errors

  include Syncable

  def initialize(event, current_user)
    @event = event
    @current_user = current_user
    @sync_errors = ErrorReport.new(self.class, @event)
    self.added = []
    self.new_people = []
    self.role = 'Participant'
  end

  def process(params)
    errors.clear
    @role = role_param(params['role'])
    i = 0
    organize_params(params).each do |pdata|
      next if pdata.values.all?(&:blank?)
      i += 1;
      check_empty_fields(pdata, i)
      person = get_a_person(pdata, i)

      if person.nil?
        @new_people << pdata
      else
        errors.delete(:"#{i}")
        i -= 1
        @added << person if add_new_member(person, @role)
      end
    end
  end

  def organize_params(params)
    data = []
    if !params['add_members'].blank?
      params['add_members'].each_line do |line|
        parts = line.chomp.split(/,/)
        record = { email: parts[0], lastname: parts[1], firstname: parts[2],
                   affiliation: parts[3] }
        data << record
      end
      data
    end

    if !params['new_people'].blank?
      params['new_people'].each do |p|
        data << p
      end
    end
    data
  end

  def check_empty_fields(pdata, i)
    pdata.each do |key, value|
      value.strip! unless value.nil?
      errors.add(i.to_s, "#{key.to_s.titleize } is required" ) if value.blank?
    end
  end

  def get_a_person(data, i)
    email = data[:email].downcase.strip
    return if email.blank?
    if EmailValidator.valid?(email)
      Rails.logger.debug "\n\n#{email} is valid email!\n\n"
      find_person(email) || add_new_person(data, i)
    else
      Rails.logger.debug "\n\n#{email} is not valid email.\n\n"
      errors.add(i.to_s, "E-mail is invalid")
      return
    end
  end

  def add_new_person(data, i)
    return if errors.messages.keys.include?(:"#{i}")
    person = Person.new(lastname: data[:lastname],
                        firstname: data[:firstname],
                        affiliation: data[:affiliation],
                        email: data[:email],
                        updated_by: @current_user.name)
    person.save!
    person
  end

  def add_new_member(person, role)
    return true if @event.members.include?(person)
    begin
      @event.set_sync_time
      m = Membership.new(event: @event, person: person, role: role,
                         updated_by: @current_user.name, update_remote: true)
      m.save
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:"0", e.message)
      msg = { problem: 'Unable to save new member',
              source: 'AddMembersForm.add_new_member',
              person: "#{person.name} (id: #{person.id})",
              membership: membership.pretty_inspect,
              error: e.pretty_inspect }
      StaffMailer.notify_sysadmin(@event, msg).deliver_now
      return false
    end
  end

  def find_person(email)
    Person.find_by_email(email) || find_remote_person(email)
  end

  def find_remote_person(email)
    remote_person = LegacyConnector.new.search_person(email)
    return if remote_person.blank?
    find_and_update_person(remote_person)
  end

  def role_param(role)
    all_roles = Membership::ROLES
    unless @current_user.is_staff?
      all_roles -= ['Contact Organizer', 'Organizer']
    end
    return role if all_roles.include?(role)
    return 'Participant'
  end
end
