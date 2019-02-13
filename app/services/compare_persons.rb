# app/services/compare_persons.rb
# Copyright (c) 2019 Banff International Research Station
#
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Evaluates which of two person records to keep
class ComparePersons
  attr_accessor :person1, :person2

  def initialize(person1, person2)
    @person1 = person1
    @person2 = person2
  end

  def better_record
    return person1 if self_updated?(person1, person2)
    return person2 if self_updated?(person2, person1)

    data_score(person1) > data_score(person2) ? person1 : person2
  end

  def self_updated?(p1, p2)
    p1.updated_by == p1.name && p2.updated_by != p2.name
  end

  def data_score(person)
    score = 0
    score += person.memberships.size
    score += person.lectures.size
    score += 200 unless person.user.nil?
    person.attributes.each_value {|v| score += size_of(v) }
    score
  end

  def size_of(val)
    return 0 unless val.is_a?(String)
    val.size
  end
end
