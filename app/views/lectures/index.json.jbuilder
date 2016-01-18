json.array!(@lectures) do |lecture|
  json.extract! lecture, :person.name, :title, :start_time, :end_time, :abstract, :authors, :publication_details
  json.url lecture_url(lecture, format: :json)
end
