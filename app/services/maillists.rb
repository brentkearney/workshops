# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# class to receive Griddler::Email object, for workshop mail lists
class Maillists
  def initialize(email)
    @email = email
  end

  def process
    Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
    Rails.logger.debug "EmailProcessor received: #{@email.inspect}"
    Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
  end
end
