FactoryGirl.define do
  factory :invitation do
    association :membership, factory: :membership
    invited_by 1
    code SecureRandom.urlsafe_base64(37)
    expires nil
    invited_on nil
    used_on nil
  end
end
