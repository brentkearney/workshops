# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Person < ActiveRecord::Base
  has_many :memberships, dependent: :destroy
  has_many :events, -> { where ("attendance != 'Not Yet Invited' AND attendance != 'Declined'") }, through: :memberships, source: :event
  has_one :user, dependent: :destroy
  has_many :invitations, foreign_key: 'invited_by'

  before_validation :downcase_email
  before_save :clean_data

  validates :email, presence: true,
                    case_sensitive: false,
                    uniqueness: true,
                    email: true
  validates :firstname, :lastname, :affiliation, :gender, :updated_by, presence: true
  validates :gender, format: { with: /(M|F|O)/, message: " must be 'M','F', or 'O'" }, allow_blank: true
  validates :phd_year, numericality: { allow_blank: true, only_integer: true }

  # app/models/concerns/person_decorators.rb
  include PersonDecorators

  private

  def clean_data
    attributes.each_value {|v| v.strip! if v.respond_to? :strip! }
  end

  def downcase_email
    self.email = self.email.downcase if self.email.present?
    self.cc_email = self.cc_email.downcase if self.cc_email.present?
    true
  end
end
