xml.rss :version => "2.0" do
  xml.title "Today's Lectures"
  xml.description "Lectures scheduled for today in #{@room}."
  xml.link @schedule_url

  @lectures.each do |lecture|
    xml.item do
      xml.title lecture.title
      xml.speaker lecture.person.name
      xml.affiliation lecture.person.affiliation
      xml.start_time lecture.start_time
      xml.end_time lecture.end_time
      xml.description lecture.abstract
    end
  end
end
