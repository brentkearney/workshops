require 'factory_bot_rails'

FactoryBot.define do
  require 'faker'

  factory :membership do |f|
    association :person, factory: :person
    association :event, factory: :event, future: true

    f.role { 'Participant' }
    f.attendance { 'Confirmed' }
    f.replied_at { Faker::Date.backward(14) }
    f.billing { %w[ABC DEF GHI].sample }
    f.room { 'ROOM' + Random.rand(0..1000).to_s }
    f.stay_id { Faker::Lorem.words(1) }
    f.has_guest { %w[true false].sample }
    f.num_guests { 0 }
    f.own_accommodation { %w[true false].sample }
    f.guest_disclaimer { true }
    f.reviewed { true }
    f.special_info { Faker::Lorem.sentence(1) }
    f.staff_notes { Faker::Lorem.sentence(1) }
    f.org_notes { Faker::Lorem.sentence(1) }
    f.updated_by { 'FactoryBot' }
  end
end
