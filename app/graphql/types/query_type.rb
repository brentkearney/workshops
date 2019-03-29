module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :lecture, LectureType, null: false do
      description 'Find a lecture record by ID'
      argument :id, ID, required: true
    end

    def lecture(id:)
      Lecture.find_by_id(id)
    end

    field :event, EventType, null: false do
      description 'Find an event by code'
      argument :code, String, required: true
    end

    def event(code:)
      Event.find_by_code(code)
    end

    field :all_events, [EventType], null: false

    # Then provide an implementation:
    def all_events
      Event.all
    end
  end
end
