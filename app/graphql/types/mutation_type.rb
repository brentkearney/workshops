module Types
  class MutationType < Types::BaseObject
    field :add_lecture, mutation: Mutations::AddLecture
    field :update_lecture, mutation: Mutations::UpdateLecture
    field :add_event, mutation: Mutations::AddEvent
  end
end
