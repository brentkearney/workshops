# ./app/services/person_with_affil_list.rb
# Copyright (c) 2021 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Returns a comma-separated list of Person names & affiliations
module PersonWithAffilList
  def self.compose(people)
    recipients = ''
    people.each do |p|
      recipients << p.name + ' (' + p.affiliation + '), '
    end
    recipients.gsub!(/, $/, '')
  end
end
