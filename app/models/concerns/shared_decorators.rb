# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module SharedDecorators
  extend ActiveSupport::Concern

  def is_usa?(country)
    return if country.blank?
    c = country.downcase
    c == 'usa' || c == 'us' || c =~ /u.s./ || c =~ /united states/
  end
end
