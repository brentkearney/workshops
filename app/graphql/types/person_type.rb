module Types
  class PersonType < Types::BaseObject
    field :id, ID, null: false
    field :lastname, String, null: false
    field :firstname, String, null: false
    field :salutation, String, null: true
    field :gender, String, null: true
    field :email, String, null: false
    field :cc_email, String, null: true
    field :url, String, null: true
    field :phone, String, null: true
    field :fax, String, null: true
    field :emergency_contact, String, null: true
    field :emergency_phone, String, null: true
    field :affiliation, String, null: true
    field :department, String, null: true
    field :title, String, null: true
    field :address1, String, null: true
    field :address2, String, null: true
    field :address3, String, null: true
    field :city, String, null: true
    field :region, String, null: true
    field :country, String, null: true
    field :postal_code, String, null: true
    field :academic_status, String, null: true
    field :phd_year, Integer, null: true
    field :biography, String, null: true
    field :research_areas, String, null: true
    field :legacy_id, Integer, null: true
    field :grant_id, Integer, null: true
    field :updated_by, String, null: true
    field :updated_at, Types::DateTimeType, null: true
    field :created_at, Types::DateTimeType, null: true
  end
end
