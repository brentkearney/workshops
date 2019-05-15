xml.xml :version => "1.0", :encoding => "UTF-8"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Current Lecture"
    xml.link @schedule_url
    xml.description "Current lecture in #{@room}."

    unless @lecture.blank?
      xml.item do
        xml.title "#{@lecture.start_time.strftime("%b %-d %H:%M")} to #{@lecture.end_time.strftime("%H:%M %z")}"
        xml.description "#{@lecture.person.name}, #{@lecture.person.affiliation}\n#{@lecture.title}"
      end
    end
  end
end
