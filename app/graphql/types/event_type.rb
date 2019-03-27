module Types
  class EventType < Types::BaseObject
    field :id, ID, null: false
    field :code, String, null: false
    field :name, String, null: false
    field :short_name, String, null: true
    field :start_date, Types::DateType, null: true
    field :end_date, Types::DateType, null: true
    field :event_type, String, null: true
    field :location, String, null: true
    field :description, String, null: true
    field :press_release, String, null: true
    field :max_participants, Integer, null: true
    field :booking_code, String, null: true
    field :time_zone, String, null: true
    field :publish_schedule, Boolean, null: true
    field :updated_by, String, null: true
    field :updated_at, Types::DateTimeType, null: true
    field :created_at, Types::DateTimeType, null: true
  end
end
