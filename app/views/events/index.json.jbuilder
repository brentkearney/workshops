json.array!(@events) do |event|
  json.extract! event, :code, :name, :short_name, :start_date, :end_date, :event_type, :location, :max_participants, :description, :press_release
  json.url event_url(event, format: :json)
end
