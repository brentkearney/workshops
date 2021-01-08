json.array!(@events) do |event|
  if user_signed_in?
    json.extract! event, :code, :name, :short_name, :start_date, :end_date, :event_type, :location, :subjects, :max_participants, :press_release, :description
  else
    json.extract! event, :code, :name, :short_name, :start_date, :end_date, :event_type, :location, :subjects, :max_participants, :press_release
  end
    json.url event_url(event, format: :json)
end
