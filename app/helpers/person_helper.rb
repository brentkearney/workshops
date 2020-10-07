# app/helpers/person_helper.rb
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module PersonHelper
  def street_address(person)
    lines = [person.address1, person.address2, person.address3].uniq
    address = ''
    lines.each do |line|
      address += line + "<br />\n" unless line.blank?
    end
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
      person.city.blank? && person.region.blank? && person.postal_code.blank?
  end

  def construct_address(person)
    address = city_and_region(person, street_address(person))
    address += "<br />\n" + person.country unless person.country.blank?
    address
  end

  def country_or_street(person)
    if !no_address?(person) && policy(@membership).show_full_address?
      construct_address(person)
    elsif person.country && policy(@membership).show_address?
      "<strong>Country:</strong>&nbsp; #{person.country}<br />\n"
    else
      ''
    end
  end

  def print_address(person)
    no_address = no_address?(person)
    return '' if person.country.blank? && no_address
    address = country_or_street(person)
    address.html_safe
  end

  def replace_email(person)
    ConfirmEmailChange.where(replace_person_id: person.id).first.replace_email
  end

  def replace_with_email(person)
    ConfirmEmailChange.where(replace_person_id: person.id).first.replace_with_email
  end
end
