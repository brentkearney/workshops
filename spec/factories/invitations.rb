FactoryGirl.define do
  factory :invitation do
    association :membership, factory: :membership
    invited_by 1
    code 'TSKCmHdVAjJ1pdOSwbCjlDbSh0IdrD-MqOGOHRWMHKVxdG8EHA'
    expires nil
    invited_on nil
    used_on nil
  end
end
