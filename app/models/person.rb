# app/models/person.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Person < ApplicationRecord
  attr_accessor :is_rsvp, :member_import

  has_many :memberships, dependent: :destroy
  has_many :events, -> {
    where "attendance != 'Not Yet Invited' AND attendance != 'Declined'"
  }, through: :memberships, source: :event
  has_one :user, dependent: :destroy
  has_many :invitations, foreign_key: 'invited_by'

  before_validation :downcase_email
  before_save :clean_data

  validates :email, presence: true,
                    case_sensitive: false,
                    uniqueness: true,
                    email: true
  validates :firstname, :lastname, :updated_by, presence: true
  validates :gender, :affiliation, presence: true, unless: :member_import
  validates :gender, format:
                     { with: /\A(M|F|O)\z/, message: " must be 'M','F', or 'O'" },
                     allow_blank: true, unless: :member_import
  validates :phd_year, numericality: { allow_blank: true, only_integer: true }
  validates :address1, :city, :country, :postal_code,
            presence: {
              message: '← address fields cannot be blank'
            }, if: :is_rsvp
  validates :phone, :academic_status, presence: true, if: :is_rsvp

  # app/models/concerns/person_decorators.rb
  include PersonDecorators

  private

  def clean_data
    attributes.each_value {|v| v.strip! if v.respond_to? :strip! }
  end

  def downcase_email
    self.email = email.downcase.strip if email.present?
    self.cc_email = cc_email.downcase.strip if cc_email.present?
  end
end
