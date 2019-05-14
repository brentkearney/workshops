# Supporting methods for lectures tests

# Create a template event with default schedule
def build_lecture_schedule(event = nil)
  @event ||= create(:event, future: true)

  @event.days.each do |eday|
    (9..12).each do |hour|
      start_time = eday.to_time.in_time_zone(@event.time_zone)
                       .change(hour: hour, min: 0)
      end_time = eday.to_time.in_time_zone(@event.time_zone)
                 .change(hour: hour, min: 30)
      lecture_title = "Lecture at #{hour}"
      create(:lecture, event: @event, start_time: start_time,
                        end_time: end_time, title: lecture_title)
    end
  end
  @event
end

def add_lectures_on(date)
  @event = create(:event, start_date: date)
  build_lecture_schedule(@event)
end
