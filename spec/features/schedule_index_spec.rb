# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Schedule Index', type: :feature do
  before do
    authenticate_user
    @event = create(:event)
    @template_event = build_schedule_template(@event.event_type)
  end

  after(:each) do
    Warden.test_reset!
  end

  def populates_empty_schedule
    @event.schedules.destroy_all
    visit(event_schedule_index_path(@event))

    @template_event.schedules.each do |item|
      expect(page.body).to have_text(item.name)
    end
  end

  def reloads_template_schedule
    visit(event_schedule_index_path(@event))
    @template_event.schedules.each do |item|
      expect(page.body).to have_text(item.name)
    end

    template_item = @template_event.schedules.third
    template_item.name = 'Altered item'
    template_item.save

    visit(event_schedule_index_path(@event))
    expect(page.body).to have_text('Altered item')
  end

  context 'Admin users' do
    before do
      @user.admin!
    end

    it 'populates an empty schedule from the template event schedule' do
      populates_empty_schedule
    end

    it 'reloads the template schedule if no schedule changes have been made' do
      reloads_template_schedule
    end
  end

  context 'Organizers' do
    before do
      membership = create(:membership, role: 'Organizer')
      authenticate_user(membership.person, 'member')
    end

    it 'populates an empty schedule from the template event schedule' do
      populates_empty_schedule
    end

    it 'reloads the template schedule if no schedule changes have been made' do
      reloads_template_schedule
    end
  end

  context 'Participants' do
    before do
      membership = create(:membership, role: 'Participant')
      authenticate_user(membership.person, 'member')
    end

    it 'does not load default schedule' do
      @event.schedules.destroy_all
      visit(event_schedule_index_path(@event))

      @template_event.schedules.each do |item|
        expect(page.body).not_to have_text(item.name)
      end
    end
  end
end
