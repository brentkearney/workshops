# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module SettingsHelper
  def person_url(person)
    link_to person.uri, person.uri unless person.url.blank?
  end

  def person_address(person)
    address = ''
    address << person.address1 + "<br />\n" unless person.address1.blank?
    address << person.address2 + "<br />\n" unless person.address2.blank?
    address << person.address3 + "<br />\n" unless person.address3.blank?
    address << person.city unless person.city.blank?
    address << ', ' + person.region unless person.region.blank?
    address << ', ' + person.postal_code unless person.postal_code.blank?
    address << "<br />\n" + person.country unless person.postal_code.blank?
    address
  end
end
