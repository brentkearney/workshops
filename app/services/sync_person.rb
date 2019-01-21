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
  attr_reader :person, :new_email
  include Syncable

  def initialize(person, new_email = nil)
    @person = person
    @new_email = new_email.downcase.strip unless new_email.nil?
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

  def names_match(n1, n2)
    I18n.transliterate(n1.downcase) == I18n.transliterate(n2.downcase)
  end

  def change_email
    return person if person.email == new_email

    # EmailForm does person.valid?, so send it back if email is invalid
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
    else
      begin
        ConfirmEmailChange.create!(replace_person: person,
                                   replace_with: other_person).send_email
      rescue ActiveRecord::RecordInvalid => e
        return person if e.message =~ /Validation failed/
        msg = { problem: 'Unable to create! new ConfirmEmailChange',
                source: 'SyncPerson.change_email',
                person: "#{person.name} (id: #{person.id}",
                error: e.inspect }
        StaffMailer.notify_sysadmin(nil, msg).deliver_now
      end
    end
    person
  end

  def confirmed_email_change(confirmation)
    replace_with_person = Person.find(confirmation.replace_with_id)
    replace_person(replace: person, replace_with: replace_with_person)
  end
end
