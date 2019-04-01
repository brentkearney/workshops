module Types
  class QueryType < Types::BaseObject
    field :lecture, Types::LectureType, null: true do
      description 'Find a lecture record by ID'
      argument :id, ID, required: true
    end
    def lecture(id:)
      Lecture.find_by_id(id)
    end


    field :lectures_today, [Types::LectureType], null: true do
      description 'Returns lectures scheduled for today in given room'
      argument :room, String, required: true
    end
    def lectures_today(room:)
      Lecture.where(room: room).where("start_time > TIMESTAMP 'yesterday' AND end_time < TIMESTAMP 'tomorrow'")
    end


    field :event, Types::EventType, null: true do
      description 'Find an event by code or id'
      argument :code, String, required: false
      argument :id, Int, required: false
    end
    def event(arg)
      Event.find(arg.flatten.last)
    end


    field :all_events, [Types::EventType], null: true
    def all_events
      Event.all
    end
  end
end
