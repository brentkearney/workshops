# app/forms/add_members_form.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/add.html.erb
class AddMembersForm < ComplexForms
  attr_accessor :added, :new_people

  include Syncable

  def initialize(event)
    @event = event
    self.added = []
    self.new_people = []
  end

  def process(params)
    errors.clear
    role = params['role']
    Rails.logger.debug "\nNew people: #{params['new_people']}\n"

    unless params['add_members'].blank?
      process_add_members(params['add_members'])
    end

    unless params['new_people'].blank?
      process_new_people(params['new_people'])
    end
  end

  def process_new_people(new_people)
    i = 0;
    new_people.each do |p|
      next if p.values.all?(&:blank?)
      i += 1;

      if p['email'].blank?
        errors.add(i.to_s, "Email is required") if p['email'].blank?
      else
        unless EmailValidator.valid?(p['email'])
          errors.add(i.to_s, "Email '#{p['email']}' is invalid")
        end
      end
      errors.add(i.to_s, "Lastname: is required" ) if p['lastname'].blank?
      errors.add(i.to_s, "Firstname is required" ) if p['firstname'].blank?
      errors.add(i.to_s, "Affiliation is required" ) if p['affiliation'].blank?

      self.new_people << [ p['email'], p['lastname'], p['firstname'], p['affiliation'] ]
    end
  end

  def process_add_members(members_to_add)
    i = 0;
    members_to_add.each_line do |line|
      i += 1
      parts = line.split(/,/)
      email = parts[0].strip

      if EmailValidator.valid?(email)
        person = find_person(email)
        if person.nil?
          parts[2] = ''
          self.new_people << parts
        else
          self.added << person
          # @event << person
        end
      else
        errors.add(i.to_s, "Email '#{email}' is invalid")
        self.new_people << parts
      end
    end

    self.added.each do |p|
      if p.respond_to? :name
        Rails.logger.debug "* #{p.name} (#{p.email}), #{p.affiliation}<br>\n"
      else
        Rails.logger.debug " --> Error: #{p.inspect}"
      end
    end

    Rails.logger.debug "\n\nTo be added members:\n"
    self.new_people.each do |f|
      Rails.logger.debug "* #{f}"
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
end
