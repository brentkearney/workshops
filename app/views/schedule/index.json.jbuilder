json.array!(@schedules) do |schedule|
  json.extract! schedule, :start_time, :end_time, :name, :description, :location
  json.is_lecture (schedule.lecture_id && schedule.lecture_id > 0) || false
end