require 'factory_bot_rails'

FactoryBot.define do
  sequence(:title) { |n| "A lectures database test (ignore) #{n}" }

  factory :lecture do |f|
    event { association :event }
    person { association :person }

    f.title
    f.start_time { (event.start_date + 1.days).to_time.in_time_zone(event.time_zone).change({ hour:9, min:0}) }
    f.end_time { (event.start_date + 1.days).to_time.in_time_zone(event.time_zone).change({ hour:10, min:0}) }
    f.room { 'TCPL 201' }
    f.do_not_publish { false }
    f.abstract { Faker::Lorem.sentence(2) }
    f.updated_by { 'FactoryBot' }
  end

end
