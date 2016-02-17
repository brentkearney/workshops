# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Organizer invitations', :type => :feature do
  before do
    @event = FactoryGirl.create(:event)
    3.times do
      person = FactoryGirl.create(:person)
      user = FactoryGirl.create(:user, email: person.email, person: person)
      FactoryGirl.create(:membership, event: @event, person: person, role: 'Organizer', attendance: 'Confirmed', sent_invitation: false)
    end

    3.times do
      person = FactoryGirl.create(:person)
      FactoryGirl.create(:membership, event: @event, person: person, role: 'Participant', attendance: 'Confirmed')
    end

    @user = FactoryGirl.create(:user, role: 'admin')
    login_as @user, scope: :user
  end

  before :each do
    visit event_memberships_path(@event)
  end

  it 'shows "Invite" buttons on the rows of uninvited organizers' do
    all('tr.organizer-row').each do |row|
      expect(row).to have_link('Invite')
    end
  end

  it 'does NOT show "Invite" buttons on rows of invited organizers' do
    organizer = @event.memberships.where("role LIKE '%Org%'").sample
    organizer.sent_invitation = true
    organizer.save
    all('tr.organizer-row').each do |row|
      if row.text =~ /organizer.person.lname/
        expect(row).not_to have_link('Invite')
      else
        expect(row).to have_link('Invite')
      end
    end
  end
end
