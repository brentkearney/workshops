# Supporting methods for schedule tests

# Create a template event with default schedule
def build_schedule_template(event_type)
  template_event = create(:event, event_type: event_type, template: true,
                                  name: 'Schedule Template Event')
  (9..16).each do |hour|
    start_time = (template_event.start_date + 1.days)
                 .to_time.in_time_zone(template_event.time_zone)
                 .change(hour: hour, min: 0)
    end_time = (template_event.start_date + 1.days)
               .to_time.in_time_zone(template_event.time_zone)
               .change(hour: hour, min: 30)
    name = "Template Item at #{hour}"
    create(:schedule, event: template_event, start_time: start_time,
                      end_time: end_time, name: name, updated_by: 'Staff')
  end
  template_event
end
