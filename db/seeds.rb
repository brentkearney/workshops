#./db/seeds.rb
#
# Generate fake data, for demo apps
# See bottom of file for variables.
require 'faker'

def generate_events(start_year, end_year)
  default_location = 'EO'
  (start_year..end_year).each do |year|
    puts "\n\nCreating events for #{year}..."
    prefix = year.to_s[-2..-1] + 'w9'
    suffix = 0

    start_date = Date.new(year,1,15).beginning_of_week(:sunday)
    48.times do
      suffix += 1
      code = prefix + (suffix).to_s.rjust(3, '0')
      start_date = start_date + 7.days
      end_date = start_date + 5.days

      event_data = {
       code: code,
       name: Faker::Lorem.sentence(4),
       short_name: Faker::Lorem.sentence(2),
       start_date: start_date,
       end_date: end_date,
       event_type: '5 Day Workshop',
       location: default_location,
       description: Faker::Movies::HitchhikersGuideToTheGalaxy.quote,
       press_release: Faker::ChuckNorris.fact,
       updated_by: 'seeds.rb',
       max_participants: 50,
       booking_code: Faker::Alphanumeric.alphanumeric(6),
       time_zone: 'Mountain Time (US & Canada)'
      }

      event = Event.create!(event_data)
      puts "Created event #{event.code}"
      add_new_members(event, [*25..50].sample)
    end
  end
end

def generate_people(num)
  i = 0
  num.times do
    i += 1
    lastname = Faker::Name.last_name
    email = lastname + i.to_s + '@' + Faker::Internet.domain_name
    person_data = {
      firstname: Faker::Name.first_name,
      lastname: lastname,
      email: email,
      affiliation: Faker::University.name,
      country: Faker::Address.country,
      legacy_id: Random.rand(1000..9999),
      salutation: %w[Mr. Mrs. Ms. Prof. Dr.].sample,
      gender: %w[M F O].sample,
      updated_by: 'Seeds'
    }
    Person.create!(person_data)
  end
end

def add_new_members(event, num)
  num_people = Person.count
  create_member(event, 'Contact Organizer', num_people)
  2.times do
    create_member(event, 'Organizer', num_people)
  end
  4.times do
    create_member(event, 'Backup Participant', num_people)
  end
  (num - 7).times do
    create_member(event, 'Participant', num_people)
  end
end

def create_member(event, role, num_people)
  person = Person.offset(rand(num_people)).first
  while event.members.include? person
    person = Person.offset(rand(num_people)).first
  end
  person.member_import = true
  member_data = {
    role: role,
    attendance: Membership::ATTENDANCE.sample,
    event: event,
    person: person,
    arrival_date: event.start_date,
    departure_date: event.end_date,
    update_remote: false,
    updated_by: 'Seeds'
  }
  Membership.create!(member_data)
end

def create_schedule_template(year)
  event_code = year.to_s[-2..-1] + 'x000'
  start_date = Date.new(year,1,7).beginning_of_week(:sunday)
  end_date = start_date + 5.days

  event = Event.find_by_code('event_code') || Event.create!({code: event_code, name: "5 Day Workshop Schedule Template", short_name: "Schedule Template", start_date: start_date, end_date: end_date, event_type: "5 Day Workshop", location: "EO", description: "A template for EO staff to configure the default schedules for 5-Day Workshops at EO.", press_release: "", max_participants: 5, door_code: nil, booking_code: "", updated_by: "db seed", template: true, time_zone: 'Mountain Time (US & Canada)'})

  t = Time.parse(start_date.to_s)
  Schedule.create!([
    {event: event, lecture_id: nil, start_time: t.change(hour: 16), end_time: t.change(hour: 23, min: 59), name: "Check-in begins at 16:00 on Sunday and is open 24 hours", description: "", location: "Front Desk", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: t.change(hour: 17, min: 30), end_time: t.change(hour: 19, min: 30), name: "Dinner", description: "A buffet dinner is served daily between 5:30pm and 7:30pm in the Dining Room.", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: t.change(hour: 20), end_time: t.change(hour: 23, min: 59), name: "Informal gathering ", description: "", location: "Main Lounge", updated_by: "db seed", staff_item: true},

    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 7, min: 0), end_time: (t + 1.day).change(hour: 8, min: 45), name: "Breakfast", description: "Breakfast is served daily between 7 and 9am in the Dining Room, the top floor of the Recreation Building.", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 8, min: 45), end_time: (t + 1.day).change(hour: 9, min: 0), name: "Introduction and Welcome by EO Station Manager", description: "", location: "Main Building 201", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 10, min: 0), end_time: (t + 1.day).change(hour: 10, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 11, min: 30), end_time: (t + 1.day).change(hour: 13, min: 0), name: "Lunch", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 13, min: 0), end_time: (t + 1.day).change(hour: 14, min: 0), name: "Guided Tour of Campus", description: "Meet in the Residence Building Lounge for a guided tour of campus.", location: "Residence Building Lounge", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 14, min: 0), end_time: (t + 1.day).change(hour: 14, min: 20), name: "Group Photo", description: "Meet in foyer of Main Building to participate in the EO group photo.", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 15, min: 0), end_time: (t + 1.day).change(hour: 15, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 1.day).change(hour: 17, min: 30), end_time: (t + 1.day).change(hour: 19, min: 30), name: "Dinner", description: "A buffet dinner is served daily between 5:30pm and 7:30pm in the Dining Room.", location: "Dining Room", updated_by: "db seed", staff_item: true},

    {event: event, lecture_id: nil, start_time: (t + 2.days).change(hour: 7, min: 0), end_time: (t + 2.days).change(hour: 9, min: 0), name: "Breakfast", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 2.days).change(hour: 10, min: 0), end_time: (t + 2.days).change(hour: 10, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 2.days).change(hour: 11, min: 30), end_time: (t + 2.days).change(hour: 13, min: 30), name: "Lunch", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 2.days).change(hour: 15, min: 0), end_time: (t + 2.days).change(hour: 15, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 2.days).change(hour: 17, min: 30), end_time: (t + 2.days).change(hour: 19, min: 30), name: "Dinner", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},

    {event: event, lecture_id: nil, start_time: (t + 3.days).change(hour: 7, min: 0), end_time: (t + 3.days).change(hour: 9, min: 0), name: "Breakfast", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 3.days).change(hour: 10, min: 0), end_time: (t + 3.days).change(hour: 10, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 3.days).change(hour: 11, min: 30), end_time: (t + 3.days).change(hour: 13, min: 0), name: "Lunch", description: "", location: "Outside", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 3.days).change(hour: 13, min: 0), end_time: (t + 3.days).change(hour: 17, min: 30), name: "Free Afternoon", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 3.days).change(hour: 17, min: 30), end_time: (t + 3.days).change(hour: 19, min: 30), name: "Dinner", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},

    {event: event, lecture_id: nil, start_time: (t + 4.days).change(hour: 7, min: 0), end_time: (t + 4.days).change(hour: 9, min: 0), name: "Breakfast", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 4.days).change(hour: 10, min: 0), end_time: (t + 4.days).change(hour: 10, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 4.days).change(hour: 11, min: 30), end_time: (t + 4.days).change(hour: 13, min: 30), name: "Lunch", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 4.days).change(hour: 15, min: 0), end_time: (t + 4.days).change(hour: 15, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 4.days).change(hour: 17, min: 30), end_time: (t + 4.days).change(hour: 19, min: 30), name: "Dinner", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},

    {event: event, lecture_id: nil, start_time: (t + 5.days).change(hour: 7, min: 0), end_time: (t + 5.days).change(hour: 9, min: 0), name: "Breakfast", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 5.days).change(hour: 10, min: 0), end_time: (t + 5.days).change(hour: 10, min: 30), name: "Coffee Break", description: "", location: "Main Building Foyer", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 5.days).change(hour: 11, min: 30), end_time: (t + 5.days).change(hour: 12, min: 0), name: "Checkout by Noon", description: "5-day workshop participants are welcome to use EO facilities until 3 pm on Friday, although participants are still required to checkout of the guest rooms by 12 noon.", location: "Front Desk", updated_by: "db seed", staff_item: true},
    {event: event, lecture_id: nil, start_time: (t + 5.days).change(hour: 12, min: 0), end_time: (t + 5.days).change(hour: 13, min: 30), name: "Lunch", description: "", location: "Dining Room", updated_by: "db seed", staff_item: true}
  ])
  event
end

# Generate a bunch of Person records
generate_people(1000)

# Generate 3 years worth of events, populated by random people
start_year = Time.new.year - 5
end_year = start_year + 0
generate_events(start_year, end_year)

# Create a schedule template event, and add admin user to it
event = create_schedule_template(start_year)
admin = User.find_by(role: :admin).person
unless admin.nil?
  Membership.create!(event: event, person: admin, role: 'Contact Organizer', attendance: 'Confirmed', updated_by: 'Seed')
end
