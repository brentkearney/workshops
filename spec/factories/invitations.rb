require 'factory_bot_rails'

FactoryBot.define do
  factory :invitation do
    association :membership, factory: :membership
    invited_by { 'FactoryBot' }
    code { SecureRandom.urlsafe_base64(37) }
    expires { nil }
    invited_on { Date.today }
    used_on { nil }
  end
end
