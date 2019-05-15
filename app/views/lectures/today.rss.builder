xml.xml :version => "1.0", :encoding => "UTF-8"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Today's Lectures"
    xml.link @schedule_url
    xml.description "Lectures scheduled for today in #{@room}."

    @lectures.each do |lecture|
      xml.item do
        xml.title lecture.person.name, lecture.person.affiliation
        xml.link lecture.watch_url
        xml.description lecture.title
      end
    end

    xml.title "No lectures scheduled today." if @lectures.blank?
  end
end
