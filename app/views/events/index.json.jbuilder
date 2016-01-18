json.array!(@events) do |event|
  json.extract! event, :id, :code, :name, :short_name, :start_date, :end_date, :event_type, :location, :description, :press_release, :max_participants, :door_code, :booking_code, :updated_by
  json.url event_url(event, format: :json)
end
