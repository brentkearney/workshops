# Copyright (c) 2021 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'PersonWithAffilList' do
  before do
    @event = create(:event_with_members)
  end

  it '.compose creates a comma-separated list of names & affils' do
    organizers = @event.organizers
    person_list = PersonWithAffilList.compose(organizers)

    organizers.each do |org|
      expect(person_list).to include("#{org.name} (#{org.affiliation})")
    end
  end
end
