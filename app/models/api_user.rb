# app/models/api_user.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class ApiUser < User
  include Devise::JWT::RevocationStrategies::JTIMatcher
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :jwt_authenticatable, jwt_revocation_strategy: self

  validates :jti, presence: true
  validate :staff?

  def generate_jwt
    JWT.encode({ id: id,
                exp: 5.days.from_now.to_i },
               Rails.env.devise.jwt.secret_key)
  end
end
