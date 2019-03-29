# app/graphql/mutations/update_lecture.rb

module Mutations
  class UpdateLecture < BaseMutation
    argument :id, ID, required: true

    argument :room, String, required: false
    argument :event_id, ID, required: false
    argument :person_id, ID, required: false
    argument :title, String, required: false
    argument :start_time, Types::DateTimeType, required: false
    argument :end_time, Types::DateTimeType, required: false
    argument :updated_by, String, required: false
    argument :legacy_id, Int, required: false
    argument :abstract, String, required: false
    argument :notes, String, required: false
    argument :keywords, String, required: false
    argument :filename, String, required: false
    argument :publish, Boolean, required: false
    argument :tweeted, Boolean, required: false
    argument :hosting_license, String, required: false
    argument :archiving_license, String, required: false
    argument :hosting_release, Boolean, required: false
    argument :archiving_release, Boolean, required: false
    argument :authors, String, required: false
    argument :copyright_owners, String, required: false
    argument :publication_details, String, required: false


    # return type from the mutation
    type Types::LectureType

    def resolve(args)
      lecture = Lecture.find(args[:id])
      if args.key?(:event_id)
        event = Event.find(args.delete(:event_id))
        args.merge!(event: event) unless event.nil?
      end
      if args.key?(:person_id)
        person = Person.find(args.delete(:person_id))
        args.merge!(person: person) unless person.nil?
      end
      lecture.update!(args)
      lecture
    end
  end
end
