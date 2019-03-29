# app/graphql/mutations/add_lecture.rb

module Mutations
  class AddLecture < BaseMutation
    argument :room, String, required: true
    argument :event_id, ID, required: true
    argument :person_id, ID, required: true
    argument :title, String, required: true
    argument :start_time, Types::DateTimeType, required: true
    argument :end_time, Types::DateTimeType, required: true
    argument :updated_by, String, required: true

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
      event = Event.find(args.delete(:event_id))
      person = Person.find(args.delete(:person_id))

      Lecture.create!(
        args.merge(event: event, person: person)
      )
    end
  end
end
