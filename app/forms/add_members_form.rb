# app/forms/add_members_form.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/add.html.erb
class AddMembersForm < ComplexForms
  attr_accessor :added, :failed, :new_people

  include Syncable

  def initialize(event)
    @event = event
    self.added = []
    self.failed = []
    self.new_people = []
  end

  def process(params)
    role = params['role']

    Rails.logger.debug "\nAddMembersForm.process received:\n#{params.inspect}\n\n"

    params['add_members'].each_line do |line|
      Rails.logger.debug "Evaluating line: #{line}"
      parts = line.split(/,/)
      email = parts[0].strip
      if EmailValidator.valid?(email)
        person = find_person(email)
        if person.nil?
          self.new_people << parts
        else
          self.added << person
          # @event << person
        end
      else
        errors.add(:"Invalid email:", email)
        self.failed << line
      end
    end

    Rails.logger.debug "\n\nNew members:\n"
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

    Rails.logger.debug "\n\nFailed members:\n"
    self.failed.each do |f|
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
