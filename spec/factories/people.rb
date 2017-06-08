# spec/factories/people.rb
require 'factory_girl_rails'
require 'faker'

FactoryGirl.define do
  sequence(:firstname) { |n| "#{n}-#{Faker::Name.first_name}" }
  sequence(:lastname) { Faker::Name.last_name }
  sequence(:email) { |n| "person-#{n}@" + Faker::Internet.domain_name }
  sequence(:legacy_id) { Random.rand(1000..9999) }

  factory :person do |f|
    f.firstname
    f.lastname
    f.salutation 'Prof.'
    f.gender ['M', 'F'].sample
    f.email
    f.url { Faker::Internet.url }
    f.phone { Faker::PhoneNumber.phone_number }
    f.affiliation { Faker::Company.name }
    f.department { Faker::Commerce.department }
    f.academic_status 'Professor'
    f.legacy_id
    f.updated_by 'FactoryGirl'
  end
end
