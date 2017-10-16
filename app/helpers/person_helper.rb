# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module PersonHelper
  def print_address(person)
    address = ''
    address += person.address1 + "<br />\n" unless person.address1.blank?
    address += person.address2 + "<br />\n" unless person.address2.blank?
    address += person.address3 + "<br />\n" unless person.address3.blank?
    address += person.city unless person.city.blank?
    address += ', ' unless person.city.blank? || person.region.blank?
    address += person.region unless person.region.blank?
    address += ' &nbsp;' + person.postal_code unless person.postal_code.blank?
    address += "<br />\n" + person.country unless person.country.blank?
    address.html_safe
  end
end
