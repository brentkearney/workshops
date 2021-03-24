# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Helper extensions to String class
class String
  # Convert strings like "3.days" into Durations (via Integer)
  def to_duration
    return 0.days unless self.match?(/\A\d+\.\w+\z/)
    parts = split('.')

    allowed = %w(minute minutes hour hours day days month months year years)
    super unless allowed.include? parts.last

    parts.first.to_i.send(parts.last)
  end

  def remove_non_ascii(replace_with="")
    self.gsub(/\P{ASCII}/, replace_with)
  end
end
