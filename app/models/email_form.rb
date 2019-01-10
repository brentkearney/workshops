# app/models/email_form.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Facilitates email change form
class EmailForm < ComplexForms
  include Syncable
  attr_accessor :person

  def initialize(person)
    @person = person
  end

  def validate_email(attributes = {})
    submitted_email = attributes['person']['email'].downcase.strip
    if @person.email != submitted_email
      if Person.find_by_email(submitted_email).blank?
        @person.email = submitted_email
      else
        swap_person(attributes['person']['email'])
      end
    end

    unless @person.valid?
      @person.errors.full_messages.each do |msg|
          errors.add('Error:', msg)
      end
    end

    @person.save! if @person.valid?
  end

  def names_match(p1, p2)
    I18n.transliterate(p1.downcase) == I18n.transliterate(p2.downcase)
  end

  def swap_person(new_email)
    return unless EmailValidator.valid?(new_email)
    other_person = Person.where(email: new_email).where.not(id: @person.id).first

    # if the names match, replace the new with the old
    if names_match(other_person.name, @person.name)
      replace_person(replace: @person, replace_with: other_person)
      @person = Person.find(other_person.id)
    # otherwise, send a confirmation email
    else
      Rails.logger.debug "Names mismatch! #{@person.name} != #{other_person.name}"
      # params = { method: :email_conflict, person: person.id,
      #            new_email: new_email, other_person: other_person.id }
      # send confirmation email to new_email?
      # EmailStaffUpdateProblem.perform_later(params)
      halt
    end
  end
end
