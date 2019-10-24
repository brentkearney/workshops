# spec/factories/events.rb
require 'factory_bot_rails'
require 'faker'

FactoryBot.define do
  sequence(:code) do |x|
    yrw5 = DateTime.current.strftime("%y") + 'w5'
    code = yrw5 + Random.rand(999).to_s.rjust(3, '0')
    while Event.where(code: code).exists?
      code = yrw5 + Random.rand(999).to_s.rjust(3, '0')
    end
    code
  end
  sequence(:start_date, 1) do |n|
    n = 1 if n > 48 # avoid going years into the future
    date = Time.zone.today.beginning_of_year.advance(weeks: 1)
    date.advance(weeks: n).beginning_of_week(:sunday)
  end
  sequence(:end_date, 1) do |n|
    n = 1 if n > 48
    date = Time.zone.today.beginning_of_year.advance(weeks: 1)
    date.advance(weeks: n, days: 5)
  end

  factory :event do |f|
    f.code
    f.name { Faker::Lorem.sentence(4) }
    f.short_name { Faker::Lorem.sentence(1) }
    f.booking_code { 'Booking' }
    f.door_code { 1234 }
    f.start_date
    f.end_date
    f.event_type { '5 Day Workshop' }
    f.max_participants { 42 }
    f.max_observers { 3 }
    f.location { 'EO' }
    f.time_zone { 'Mountain Time (US & Canada)' }
    f.description { Faker::Lorem.sentence(6) }
    f.updated_by { 'FactoryBot' }
    f.template { false }

    transient do
      past    { false }
      future  { false }
      current { false }
    end

    after(:build) do |event, evaluator|
      date = Date.today
      date = date + 3.weeks if date.month == 1
      if evaluator.past
        date = date.prev_year #- 2.months
        event.start_date = date.prev_week(:sunday)
      elsif evaluator.future
        date = date.next_year
        event.start_date = date.next_week(:sunday)
      elsif evaluator.current
        weekends = %w(Friday Saturday Sunday)
        if date.strftime("%A").match(Regexp.union(weekends))
          event.start_date = date.beginning_of_week(:friday)
        else
          event.start_date = date.beginning_of_week(:sunday)
        end
      end
      event.end_date = event.start_date + 5.days unless event.start_date.nil?

      if event.start_date
        event.code.gsub!(/^\d{2}/, event.start_date.strftime('%y'))
      end
    end

    factory :event_with_roles do
      after(:create) do |event|
        Membership::ROLES.shuffle.each do |role|
          person = create(:person)
          create(:membership, role: role, person: person, event: event)
        end
      end
    end

    factory :event_with_members do
      after(:create) do |event|
        arrival = event.start_date
        departure = event.end_date
        create(:membership, event: event, role: 'Contact Organizer', arrival_date: arrival, departure_date: departure)
        create(:membership, event: event, role: 'Organizer', arrival_date: arrival, departure_date: departure)
        create(:membership, event: event, role: 'Observer', attendance: 'Confirmed', arrival_date: arrival, departure_date: departure)
        create(:membership, event: event, role: 'Observer', attendance: 'Not Yet Invited')
        3.times do
          create(:membership, event: event, role: 'Participant', attendance: 'Confirmed', arrival_date: arrival, departure_date: departure)
        end
        create(:membership, event: event, role: 'Participant', attendance: 'Not Yet Invited')
        create(:membership, event: event, role: 'Participant', attendance: 'Invited')
        create(:membership, event: event, role: 'Participant', attendance: 'Undecided')
        create(:membership, event: event, role: 'Backup Participant', attendance: 'Not Yet Invited')
        create(:membership, event: event, role: 'Participant', attendance: 'Declined')
      end
    end

    factory :event_with_schedule do
      after(:create) do |event|
        9.upto(12) do |t|
          create(:schedule,
            event: event,
            name: "Item at #{t}",
            start_time: (event.start_date + 2.days).to_time.change({ hour: t }),
            end_time: (event.start_date + 2.days).to_time.change({ hour: t+1 })
          )
        end
      end
    end
  end
end


