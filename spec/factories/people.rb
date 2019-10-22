# spec/factories/people.rb
require 'factory_bot_rails'
require 'faker'

FactoryBot.define do
  sequence(:firstname) { |n| "#{n}-#{Faker::Name.first_name}" }
  sequence(:lastname) { Faker::Name.last_name }
  sequence(:email) { |n| "person-#{n}@" + Faker::Internet.domain_name }
  sequence(:legacy_id) { Random.rand(1000..9999) }

  factory :person do |f|
    f.firstname
    f.lastname
    f.salutation { 'Prof.' }
    f.gender { %w[M F].sample }
    f.email
    f.url { Faker::Internet.url }
    f.phone { Faker::PhoneNumber.phone_number }
    f.affiliation { Faker::University.name }
    f.department { Faker::Commerce.department }
    f.academic_status { 'Professor' }
    f.address1 { Faker::Address.street_address }
    f.city { Faker::Address.city }
    f.postal_code { Faker::Address.postcode }
    f.region { Faker::Address.state }
    f.country { Faker::Address.country }
    f.legacy_id
    f.biography { Faker::Lorem.paragraph }
    f.research_areas { Faker::Lorem.words(4).join(', ') }
    f.updated_by { 'FactoryBot' }
  end
end
