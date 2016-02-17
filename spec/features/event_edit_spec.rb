# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Edit Page', :type => :feature do
  before do
    @event = FactoryGirl.create(:event)
    person = FactoryGirl.create(:person)
    @member = FactoryGirl.create(:membership, event: @event, person: person, role: 'Participant', attendance: 'Confirmed')
    @user = FactoryGirl.create(:user, email: person.email, person: person)
    @non_member_user = FactoryGirl.create(:user)
  end

  after(:each) do
    Warden.test_reset!
  end

  def access_denied
    expect(page.body).to have_css('div.alert.alert-alert', :text => 'You need to sign in or sign up before continuing.')
    expect(page.body).not_to include(@event.description)
  end

  def not_ready_yet
    expect(page.body).to have_css('div.alert.alert-error', :text => 'This functionality is not ready for you, yet.')
    expect(page.body).not_to include(@event.description)
  end

  it 'Only allows access to admin users' do
    visit edit_event_path(@event)
    access_denied

    login_as @user, scope: :user
    visit edit_event_path(@event)
    not_ready_yet

    @member.role = 'Organizer'
    @member.save!
    visit edit_event_path(@event)
    not_ready_yet

    login_as @non_member_user, scope: :user
    visit edit_event_path(@event)
    not_ready_yet

    @non_member_user.staff!
    @non_member_user.location = @event.location
    visit edit_event_path(@event)
    not_ready_yet

    @non_member_user.location = 'Elsewhere'
    visit edit_event_path(@event)
    not_ready_yet

    @non_member_user.admin!
    visit edit_event_path(@event)
    expect(page.body).not_to have_css('div.alert.alert-alert', :text => 'You need to sign in or sign up before continuing.')
    expect(page.body).not_to have_css('div.alert.alert-error', :text => 'This functionality is not ready for you, yet.')
    expect(page.body).to include(@event.description)
    expect(page.body).to have_button('Update Event')
  end

end
