# app/helpers/person_helper.rb
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module PersonHelper
  def street_address(person)
    address = ''
    address += person.address1 + "<br />\n" unless person.address1.blank?
    address += person.address2 + "<br />\n" unless person.address2.blank? ||
      person.address2 == person.address1
    address += person.address3 + "<br />\n" unless person.address3.blank? ||
      person.address3 == person.address1 || person.address3 == person.address2
    address
  end

  def city_and_region(person, address)
    address += person.city unless person.city.blank?
    address += ', ' unless person.city.blank? || person.region.blank?
    address += person.region unless person.region.blank?
    address += ' &nbsp;' + person.postal_code unless person.postal_code.blank?
    address
  end

  def no_address?(person)
    person.address1.blank? && person.address2.blank? && person.address3.blank? &&
      person.city.blank? && person.region.blank? && person.postal_code.blank? &&
      person.country.blank?
  end

  def print_address(person)
    return '' if no_address?(person)
    if policy(@membership).show_address?
      address = "<strong>Address:</strong><br />\n"
      address = city_and_region(person, street_address(person))
      address += "<br />\n" + person.country unless person.country.blank?
    else
      unless person.country.blank?
        address = "<strong>Country:</strong> #{person.country}<br />\n"
      end
    end
    address.html_safe
  end

  def replace_email(person)
    ConfirmEmailChange.where(replace_person_id: person.id).first.replace_email
  end

  def replace_with_email(person)
    ConfirmEmailChange.where(replace_person_id: person.id).first.replace_with_email
  end
end
