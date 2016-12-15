FactoryGirl.define do
  require 'faker'

  factory :user do |f|
    association :person, factory: :person
    password ||= Faker::Internet.password(12)

    f.email { Faker::Internet.email("#{self.person.firstname}") }
    f.password password
    f.password_confirmation password
    f.confirmed_at Time.now
    f.location Setting.get_all['Locations'].keys.first

    trait :staff do
      role 'staff'
    end

    trait :admin do
      role 'admin'
    end

    trait :super_admin do
      role 'super_admin'
    end

  end
end
