class Invitation < ActiveRecord::Base
  belongs_to :membership
  belongs_to :person, foreign_key: 'invited_by'

  validates :membership, presence: true
  validates :invited_by, presence: true
  validates :code, presence: true, length: { is: 50 }

  after_initialize :generate_code
  before_save :set_expiry

  def generate_code
    if self.code.blank?
      self.code = SecureRandom.urlsafe_base64(37)
    end
  end

  def set_expiry
    self.expires = Time.now + 240.days if self.expires.blank?
  end
end
