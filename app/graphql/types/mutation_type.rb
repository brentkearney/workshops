module Types
  class MutationType < Types::BaseObject
    field :add_lecture, mutation: Mutations::AddLecture
    field :update_lecture, mutation: Mutations::UpdateLecture
    field :add_event, mutation: Mutations::AddEvent

    field :login, UserType, null: true do
      argument :email, String, required: true
      argument :password, String, required: true
    end
    def login(email:, password:)
      user = User.find_for_authentication(email: email)
      return nil if user.nil?

      is_valid_for_auth = user.valid_for_authentication? {
        user.valid_password?(password)
      }
      return is_valid_for_auth ? user : nil
    end

    field :token_login, UserType, null: true
    def token_login
      context[:current_user]
    end

    field :logout, Boolean, null: true
    def logout
      if context[:current_user]
        context[:current_user].update(jti: SecureRandom.uuid)
      end
      true
    end
  end
end
