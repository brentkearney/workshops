# app/services/sync_person.rb
# Copyright (c) 2018 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# updates one person record with data from remote db
class SyncPerson
  attr_reader :person
  include Syncable

  def initialize(person)
    @person = person
    sync_person
  end

  def sync_person
    return if person.legacy_id.blank?
    lc = LegacyConnector.new
    remote_person = lc.get_person(person.legacy_id)
    return if remote_person.blank?
    return if person.updated_at.to_i >= remote_person['updated_at'].to_i

    local_person = update_record(person, remote_person)
    save_person(local_person)
  end

  def names_match(p1, p2)
    I18n.transliterate(p1.downcase) == I18n.transliterate(p2.downcase)
  end

  def self.change_email(person, new_email)
    new_email = new_email.downcase.strip
    return person if person.email == new_email

    # Attempts to save this record will throw invalid email error
    unless EmailValidator.valid?(new_email)
      person.email = new_email
      return person
    end

    other_person = Person.where(email: new_email).where.not(id: person.id).first
    if other_person.nil?
      person.email = new_email
      return person
    end

    # if the names match, replace the new with the old
    if names_match(other_person.name, person.name)
      replace_person(replace: person, replace_with: other_person)
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
