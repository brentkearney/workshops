class Invitation < ActiveRecord::Base
  belongs_to :membership
  attr_accessor :organizer_message

  validates :membership, presence: true
  validates :invited_by, presence: true
  validates :code, presence: true, length: { is: 50 }

  after_initialize :generate_code
  before_save :update_times

  # Invitations expire EXPIRES_BEFORE an event starts
  EXPIRES_BEFORE = 3.days

  def generate_code
    self.code = SecureRandom.urlsafe_base64(37) if self.code.blank?
  end

  def send_invite
    self.save
    InvitationMailer.invite(self).deliver_now
  end

  def update_times
    self.invited_on = Time.now
    if self.expires.blank?
      self.expires = self.membership.event.start_date - EXPIRES_BEFORE
    end
  end

  def expire_date
    expires.strftime("%B %-d, %Y")
  end

  def accept
    update_membership('Confirmed')
    SendParticipantConfirmationJob.perform_later(self.membership_id)
    self.destroy
  end

  def decline
    update_membership('Declined')
    self.destroy
  end

  def maybe
    update_membership('Undecided')
  end

  private

  def update_membership(status)
    membership.attendance = status
    membership.updated_by = membership.person.name
    membership.replied_at = Time.now

    OrganizerMailer.rsvp_notice(self.membership, organizer_message).deliver_now
    membership.sync_remote = true
    membership.save
  end
end
