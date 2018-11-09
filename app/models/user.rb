# app/models/user.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class User < ApplicationRecord
  devise :registerable, :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :confirmable, :invitable

  validates :email, presence: true, email: true
  validates :person, presence: true
  validates :location, presence: true, if: :staff?

  belongs_to :person, inverse_of: :user

  enum role: [:member, :staff, :admin, :super_admin]
  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    role ||= :member
  end

  def is_admin?
    self.admin? || self.super_admin?
  end

  def is_staff?
    self.staff? || self.is_admin?
  end

  def is_organizer?(event)
    person.memberships.where("event_id=#{event.id} AND role LIKE '%Org%'")
          .count > 0
  end

  def is_member?(event)
    person.memberships.where("event_id=#{event.id} AND attendance != 'Declined'
      AND attendance != 'Not Yet Invited'").count > 0
  end

  def name
    person.name
  end

end
