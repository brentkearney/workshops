json.array!(@events) do |event|
  json.extract! event, :code, :name, :start_date, :end_date, :event_type, :location, :description, :press_release
  json.url event_url(event, format: :json)
end
