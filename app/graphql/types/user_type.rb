module Types
  class UserType < BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :person_id, Integer, null: false
    field :web_token, String, null: true
  end
end
