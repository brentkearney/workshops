# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Schedule Index', type: :feature do
  before do
    authenticate_user
    @event = create(:event, future: true)
    @template_event = build_schedule_template(@event.event_type)
  end

  after(:each) do
    Warden.test_reset!
  end

  def populates_empty_schedule
    @event.schedules.destroy_all
    visit(event_schedule_index_path(@event))

    @event.reload
    expect(@event.schedules).not_to be_empty
    @template_event.schedules.each do |item|
      expect(page.body).to have_text(item.name)
    end
  end

  def does_not_populate_empty_schedule
    @event.schedules.destroy_all
    visit(event_schedule_index_path(@event))

    expect(@event.schedules).to be_empty
  end

  def reloads_template_schedule
    @event.schedules.destroy_all

    visit(event_schedule_index_path(@event))
    @template_event.schedules.each do |item|
      expect(page.body).to have_text(item.name)
    end

    template_item = @template_event.schedules.third
    template_item.name = 'Altered item'
    template_item.save

    visit(event_schedule_index_path(@event))
    expect(page.body).to have_text('Altered item')
    expect(@event.schedules.count).to eq(@template_event.schedules.count)
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

  context 'Organizers of event' do
    before do
      @user.member!
      create(:membership, event: @event,
                          person: @user.person,
                          role: 'Organizer')
    end

    it 'populates an empty schedule from the template event schedule' do
      populates_empty_schedule
    end

    it 'reloads the template schedule if no schedule changes have been made' do
      reloads_template_schedule
    end

    it 'has delete buttons on schedule items' do
      @event.schedules.destroy_all

      visit(event_schedule_index_path(@event))
      @event.reload
      expect(@event.schedules).not_to be_empty

      @event.schedules.each do |item|
        item_path = "/events/#{@event.code}/schedule/#{item.id}"
        delete_link = page.find(:xpath, "//a[@href='#{item_path}'
          and @data-method='delete']")
        expect(delete_link).not_to be_nil
      end
    end

    it 'has no delete buttons on staff items when current time is within lock
      period' do
      @event.schedules.destroy_all

      lc = @event.location
      lead_time = Setting.Locations[lc]['lock_staff_schedule'].to_duration
      @event.start_date = Date.current + lead_time - 3.days
      @event.end_date = @event.start_date + 5.days
      @event.save
      @event.reload
      # puts "Event: #{@event.inspect}"

      visit(event_schedule_index_path(@event))
      @event.reload
      expect(@event.schedules).not_to be_empty

      @event.schedules.each do |item|
        item_path = "/events/#{@event.code}/schedule/#{item.id}"
        expect(page).to have_no_selector(:xpath, "//a[@href='#{item_path}'
          and @data-method='delete']")
      end
    end
  end

  context 'Organizers of other event' do
    before do
      Membership.destroy_all
      new_event = create(:event)
      create(:membership, event: new_event,
                          person: @user.person,
                          role: 'Organizer')
    end

    it 'does not populates an empty schedule from the template' do
      does_not_populate_empty_schedule
    end
  end

  context 'Participants' do
    before do
      membership = create(:membership, role: 'Participant')
      authenticate_user(membership.person, 'member')
    end

    it 'does not populates an empty schedule from the template' do
      does_not_populate_empty_schedule
    end
  end
end
