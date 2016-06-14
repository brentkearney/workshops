# spec/factories/events.rb
require 'faker'

random_code = rand(10..17).to_s + 'w50' + rand(10..99).to_s

FactoryGirl.define do
  sequence(:code) { |n| DateTime.now.strftime("%y") + 'w5' + n.to_s.rjust(3, '0') }
  sequence(:start_date, 1) { |n| Date.new(2016,1,10).advance(weeks: n).beginning_of_week(:sunday) }
  sequence(:end_date, 1) { |n| Date.new(2016,1,10).advance(weeks: n, days: 5).beginning_of_week(:friday) }

  factory :event do |f|
    f.code
    f.name { Faker::Lorem.sentence(4) }
    f.short_name { Faker::Lorem.sentence(1) }
    f.booking_code 'Booking'
    f.door_code 1234
    f.start_date
    f.end_date
    f.event_type Global.event.types.first
    f.max_participants 42
    f.location Global.location.first
    f.time_zone Global.location.timezone.send(Global.location.first)
    f.description { Faker::Lorem.sentence(6) }
    f.updated_by 'FactoryGirl'
    f.template false

    transient do
      past    false
      future  false
      current false
    end

    after(:build) do |event, evaluator|
      if evaluator.past
        event.start_date = Date.today.prev_year.prev_week(:sunday)
        event.end_date = Date.today.prev_year.prev_week(:sunday) + 5.days
      elsif evaluator.future
        event.start_date = Date.today.next_year.next_week(:sunday)
        event.end_date = Date.today.next_year.next_week(:sunday) + 5.days
      elsif evaluator.current
        event.start_date = Date.today.beginning_of_week(:sunday)
        event.end_date = Date.today.beginning_of_week(:sunday) + 7.days
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
        5.times do
          create(:membership, event: event, role: 'Participant', attendance: 'Confirmed', arrival_date: arrival, departure_date: departure)
        end
        4.times do
          create(:membership, event: event, role: 'Participant', attendance: 'Not Yet Invited')
        end
        3.times do
          membership = create(:membership, event: event, role: 'Participant', attendance: 'Declined')
        end
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


