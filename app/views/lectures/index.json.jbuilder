json.array!(@lectures) do |lecture|
  json.extract! lecture, :id, :legacy_id, :start_time, :end_time
  json.person lecture.person.name
  json.affiliation lecture.person.affiliation
  json.person_url lecture.person.url
  json.extract! lecture, :title, :abstract, :authors, :keywords, :do_not_publish, :filename, :watch_url, :video_url
end
