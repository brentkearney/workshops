# app/graphql/mutations/add_event.rb

module Mutations
  class AddEvent < BaseMutation
    argument :code, String, required: true
    argument :name, String, required: true
    argument :start_date, String, required: true
    argument :end_date, String, required: true
    argument :event_type, String, required: true
    argument :location, String, required: true
    argument :max_participants, Integer, required: true

    argument :short_name, String, required: false
    argument :description, String, required: false
    argument :time_zone, String, required: false
    argument :press_release, String, required: false
    argument :booking_code, String, required: false
    argument :publish_schedule, Boolean, required: false
    argument :updated_by, String, required: false

    # return type from the mutation
    type Types::EventType

    def resolve(args)
      if args[:time_zone].blank?
        args[:time_zone] = GetSetting.location_timezone(args[:location])
      end
      args[:updated_by] = 'Workshops API' if args[:updated_by].blank?
      Event.create!(args)
    end
  end
end
