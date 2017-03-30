class Invitation < ActiveRecord::Base
  belongs_to :membership
  belongs_to :person, foreign_key: 'invited_by'

  validates :membership, presence: true
  validates :invited_by, presence: true
  validates :code, presence: true, length: { is: 50 }

  after_initialize :generate_code
  before_save :update_times

  def generate_code
    self.code = SecureRandom.urlsafe_base64(37) if self.code.blank?
  end

  def send_invite
    self.save
    InvitationMailer.invite(self).deliver_now
  end

  def update_times
    self.expires = Time.now + 240.days if self.expires.blank?
    self.invited_on = Time.now
  end
end
