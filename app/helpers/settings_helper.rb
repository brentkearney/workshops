# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module SettingsHelper
  def person_url(person)
    link_to person.uri, person.uri unless person.url.blank?
  end

  def addr_suffix(field)
    return "<br>\n" if field.match?(/address/)
  end

  def addr_prefix(field)
    return ', ' if field == 'region'
    return ' ' if field == 'postal_code'
    return "<br>\n" if field == 'country'
  end

  def person_address(person)
    address = ''
    %w(address1 address2 address3 city region postal_code country).each do |f|
      address << addr_prefix(f) << f << addr_suffix(f) unless person.send(f).blank?
    end
    address
  end
end
