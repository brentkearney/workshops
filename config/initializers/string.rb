# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Helper extensions to String class
class String
  # Convert strings like "3.days" into Durations (via Integer)
  def to_duration
    super unless self =~ /\A\d+\.\w+\z/
    parts = split('.')
    parts.first.to_i.send(parts.last)
  end
end
