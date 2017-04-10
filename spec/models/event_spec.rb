# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe "Model validations: Event ", type: :model do
  it "has valid factory" do
    event = build(:event)
    expect(event).to be_valid
  end

  it "factory produces legitimate start and end dates" do
    event = create(:event)
    expect(event.start_date.to_time.to_i).to be < event.end_date.to_time.to_i
  end

  it "is invalid without a name" do
    expect(build(:event, name: nil)).not_to be_valid
  end

  it "is invalid without a start date" do
    expect(build(:event, start_date: nil)).not_to be_valid
  end

  it "is invalid without an end date" do
    expect(build(:event, end_date: nil)).not_to be_valid
  end

  it "is invalid without a location" do
    expect(build(:event, location: nil)).not_to be_valid
  end

  it "is invalid without max participants" do
    expect(build(:event, max_participants: nil)).not_to be_valid
  end

  it 'is invalid without a time zone' do
    expect(build(:event, time_zone: nil)).not_to be_valid
  end

  it "is invalid if the name is longer than 68 characters and it has no short name" do
    e = build(:event, name: Faker::Lorem.paragraph(5), short_name: nil)
    expect(e).not_to be_valid
    expect(e.errors).to include(:short_name)
  end

  it "is invalid if the short name is also longer than 68 characters" do
    e = build(:event, name: Faker::Lorem.paragraph(5), short_name: Faker::Lorem.paragraph(5))
    expect(e).not_to be_valid
    expect(e.errors).to include(:short_name)
  end

  it "is invalid if the code is not unique" do
    first_event = create(:event)
    dupe_event = build(:event, code: first_event.code)
    expect(dupe_event).not_to be_valid
    expect(dupe_event.errors).to include(:code)
  end

  # This is going to be organization-specific; set regex in
  # Setting.Site.code_pattern
  it "is invalid if the code has improper format" do
	  event_codes = %w[LSD w5042 12s9230 14w51234 15frg12] # invalid codes
	  event_codes.each do |code|
	    e = Event.new(code: code)
	    expect(e.valid?).to be_falsey
	    expect(e.errors[:code].any?).to be_truthy
    end
	end

	it "is valid if the event code has proper format" do
	  event_codes = %w[13w2145 14w5042 12ss130 10rit100 15frg129 13pl003] # valid
	  event_codes.each do |code|
	    e = build(:event, code: code)
	    expect(e.valid?).to be_truthy
	    expect(e.errors[:code].any?).to be_falsey
    end
  end

  it "is invalid without an event type" do
    expect(build(:event, event_type: nil)).not_to be_valid
  end

  it "is invalid if the event type is not part of Event::EVENT_TYPES" do
    expect(build(:event, event_type: 'Keg Party')).not_to be_valid
  end

  it "can find based on code (instead of just id)" do
    e = create(:event)
    found = Event.find(e.code)
    expect(found.name).to eq(e.name)
  end

  it "members returns a collection of person objects" do
    e = create(:event)
    p1 = create(:person)
    p2 = create(:person)
    m1 = create(:membership, event: e, person: p1)
    m2 = create(:membership, event: e, person: p2)

    expect(e.members).to include(p1, p2)
  end

  it "automatically truncates leading and trailing whitespace around text fields" do
    e = create(:event, name: ' Test Name ', short_name: ' Test ', description: ' A workshop with whitespace  ')

    expect(e.name).to eq('Test Name')
    expect(e.short_name).to eq('Test')
    expect(e.description).to eq('A workshop with whitespace')

    e.name = ' Testing save function too  '
    e.save
    expect(e.name).to eq('Testing save function too')
  end

  it '.years returns an array of years in which events take place' do
    Event.destroy_all
    @past = create(:event, past: true)
    @current = create(:event, current: true)
    @future = create(:event, future: true)

    expect(Event.years).to eq([@past.year, @current.year, @future.year])
  end

  describe 'Event Scopes' do
    before do
      @past = create(:event, past: true)
      @current = create(:event, current: true)
      @future = create(:event, future: true)
    end

    it ":past scope returns events in the past" do
      events = Event.past
      expect(events).to include(@past)
      expect(events).not_to include(@current, @future)
    end

    it ":future scope returns current & future events" do
      events = Event.future
      expect(events).to include(@current, @future)
      expect(events).not_to include(@past)
    end

    it ":year scope returns events in a given year" do
      events = Event.year(Date.today.strftime('%Y'))
      expect(events).to include(@current)
      expect(events).not_to include(@past, @future)
    end

    it ":kind scope returns events of a given kind" do
      @past.event_type = '5 Day Workshop'
      @past.save
      @current.event_type = '5 Day Workshop'
      @current.save
      @future.event_type = '2 Day Workshop'
      @future.save

      events = Event.kind('5 Day Workshop')
      expect(events).to include(@past, @current)
      expect(events).not_to include(@future)

      events = Event.kind('2 Day Workshop')
      expect(events).to include(@future)
      expect(events).not_to include(@past, @current)
    end
  end

  ###
  #####instance methods from app/models/concerns/event_decorators.rb #########
  ###
  it '.year returns the year as a string' do
    event = build(:event)
    expect(event.year).to eq(event.start_date.strftime('%Y'))
  end

  it '.country from Setting.Locations' do
    country = Setting.Locations.first.second['Country']

    event = build(:event, location: Setting.Locations.keys[0])

    expect(event.country).to eq(country)
  end

  it '.organizer returns Person whose role is Contact Organizer' do
    event = create(:event_with_roles)
    organizer = event.memberships.where(role: 'Contact Organizer').first
    expect(event.organizer).to eq(organizer.person)
  end

  it '.days returns a collection of Time objects for each day of the event' do
    e = create(:event, start_date: '2015-05-04', end_date: '2015-05-07')
    edays = e.days

    expect(edays[0].strftime("%A")).to eq("Monday")
    expect(edays[1].strftime("%A")).to eq("Tuesday")
    expect(edays[2].strftime("%A")).to eq("Wednesday")

    e.destroy
  end

  it '.days returns *only* the days of the event' do
    e = create(:event, start_date: '2015-05-04', end_date: '2015-05-07')
    event_start = e.start_date.to_time.to_i
    event_end = e.end_date.to_time.change({ hour: 15 }).to_i

    e.days.each do |day|
      expect(day.to_i).to be >= event_start
      expect(day.to_i).to be <= event_end
    end

    e.destroy
  end

  it ".member_info returns hash of names and afilliations" do
    e = create(:event)
    p1 = create(:person)
    p2 = create(:person)
    m1 = create(:membership, event: e, person: p1, role: 'Contact Organizer')
    m2 = create(:membership, event: e, person: p2, role: 'Organizer')

    e.members.each do |person|
      info = e.member_info(person)
      expect(info['firstname']).to eq(person.firstname)
      expect(info['lastname']).to eq(person.lastname)
      expect(info['affiliation']).to eq(person.affiliation)
      expect(info['url']).to eq(person.url)
    end

    e.destroy
  end

  it ".attendance returns a collection of members in order of Event:ROLES" do
    event = create(:event_with_roles)
    members = event.attendance
    i = 0
    Membership::ROLES.each do |role|
      expect(members[i].role).to eq(role)
      i += 1
    end

    event.destroy
  end

  it ".num_attendance returns the number of members for a given attendance status" do
    e = create(:event)
    2.times do
      p = create(:person)
      create(:membership, event: e, person: p, attendance: 'Not Yet Invited')
    end
    1.times do
      p = create(:person)
      create(:membership, event: e, person: p, attendance: 'Declined')
    end
    4.times do
      p = create(:person)
      create(:membership, event: e, person: p, attendance: 'Confirmed')
    end
    3.times do
      p = create(:person)
      create(:membership, event: e, person: p, attendance: 'Invited')
    end

    expect(e.num_attendance('Invited')).to eq(3)
    expect(e.num_attendance('Confirmed')).to eq(4)
    expect(e.num_attendance('Declined')).to eq(1)
    expect(e.num_attendance('Not Yet Invited')).to eq(2)

    e.destroy
  end

  it ".has_attendance returns true if there are any members for a given attendence status" do
    e = create(:event)
    2.times do
      p = create(:person)
      create(:membership, event: e, person: p, attendance: 'Not Yet Invited')
    end
    1.times do
      p = create(:person)
      create(:membership, event: e, person: p, attendance: 'Declined')
    end

    expect(e.has_attendance('Not Yet Invited')).to be_truthy
    expect(e.has_attendance('Invited')).to be_falsey
    expect(e.has_attendance('Declined')).to be_truthy
    expect(e.has_attendance('Undecided')).to be_falsey

    e.destroy
  end

  it ".dates returns formatted dates" do
    e = build(:event)

    expect(e.dates).to match(/^\D+ \d+ -.+\d+$/) # e.g. May 8 - 13
  end

  it ".arrival_date and .departure_date return formatted start_date and end_date" do
    e = build(:event)

    expect(e.arrival_date).to match(/^\w+,\ \w+\ \d+,\ \d{4}$/) # e.g. Friday, May 8, 2015
    expect(e.departure_date).to match(/^\w+,\ \w+\ \d+,\ \d{4}$/)
  end

  context '.is_current?' do
    it 'false if current time is outside event dates' do
      e = build(:event, future: true)

      expect(e.is_current?).to be_falsey
    end

    it 'true if current time is inside event dates' do
      e = build(:event, current: true)

      expect(e.is_current?).to be_truthy
    end
  end
end
