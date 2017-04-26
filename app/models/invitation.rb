class Invitation < ActiveRecord::Base
  belongs_to :membership
  attr_accessor :organizer_message

  validates :membership, presence: true
  validates :invited_by, presence: true
  validates :code, presence: true, length: { is: 50 }

  after_initialize :generate_code
  before_save :update_times

  def generate_code
    code = SecureRandom.urlsafe_base64(37) if code.blank?
  end

  def send_invite
    self.save
    InvitationMailer.invite(self).deliver_now
  end

  def update_times
    self.invited_on = Time.now
    self.expires = self.membership.event.start_date - 1.month if self.expires.blank?
  end

  def expire_date
    expires.strftime("%B %-d, %Y")
  end

  def decline!
    membership.attendance = 'Declined'
    OrganizerMailer.rsvp_notice(self.membership, organizer_message).deliver_now
    membership.sync_remote = true
    membership.save
    self.destroy
  end

  def maybe!
    membership.attendance = 'Undecided'
    OrganizerMailer.rsvp_notice(self.membership, organizer_message).deliver_now
    membership.sync_remote = true
    membership.save
  end
end
