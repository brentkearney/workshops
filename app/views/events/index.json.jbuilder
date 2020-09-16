json.array!(@events) do |event|
  json.extract! event, :code, :name, :short_name, :start_date, :end_date, :event_type, :location, :subjects, :max_participants, :press_release
  json.url event_url(event, format: :json)
end
