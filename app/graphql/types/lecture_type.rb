module Types
  class LectureType < Types::BaseObject
    field :id, ID, null: false
    field :legacy_id, Int, null: true
    field :event, [Types::EventType], null: false
    field :person, [Types::PersonType], null: false
    field :title, String, null: true
    field :start_time, Types::DateTimeType, null: false
    field :end_time, Types::DateTimeType, null: false
    field :abstract, String, null: true
    field :notes, String, null: true
    field :room, String, null: true
    field :keywords, String, null: true
    field :filename, String, null: true
    field :publish, Boolean, null: false
    field :tweeted, Boolean, null: false
    field :hosting_license, String, null: true
    field :archiving_license, String, null: true
    field :hosting_release, Boolean, null: true
    field :archiving_release, Boolean, null: true
    field :authors, String, null: true
    field :copyright_owners, String, null: true
    field :publication_details, String, null: true
    field :updated_by, String, null: true
    field :updated_at, Types::DateTimeType, null: true
    field :created_at, Types::DateTimeType, null: true
  end
end
