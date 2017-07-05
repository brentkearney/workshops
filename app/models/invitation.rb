class Invitation < ActiveRecord::Base
  belongs_to :membership
  attr_accessor :organizer_message

  validates :membership, presence: true
  validates :invited_by, presence: true
  validates :code, presence: true, length: { is: 50 }

  after_initialize :generate_code
  before_save :update_times

  def generate_code
    self.code = SecureRandom.urlsafe_base64(37) if self.code.blank?
  end

  def send_invite
    save
    EmailInvitationJob.perform_later(id)
  end

  def expire_date
    expires.strftime("%B %-d, %Y")
  end

  def accept
    update_membership('Confirmed')
    EmailParticipantConfirmationJob.perform_later(membership.id)
    destroy
  end

  def decline
    update_membership('Declined')
    destroy
  end

  def maybe
    update_membership('Undecided')
  end

  def self.invalid_rsvp_setting
    Setting.Site.blank? || Setting.Site['rsvp_expiry'].blank? ||
      Setting.Site['rsvp_expiry'] !~ /\A\d+\.\w+$/
  end

  def self.duration_setting
    return 3.days if invalid_rsvp_setting
    parts = Setting.Site['rsvp_expiry'].split('.')
    parts.first.to_i.send(parts.last)
  end

  # Invitations expire EXPIRES_BEFORE an event starts
  EXPIRES_BEFORE = duration_setting

  def update_times
    self.invited_on = Time.now
    if self.expires.blank?
      self.expires = self.membership.event.start_date - EXPIRES_BEFORE
    end
  end

  private

  def update_membership_fields(status)
    membership.attendance = status
    membership.replied_at = DateTime.current
    membership.updated_by = membership.person.name
  end

  def update_person_fields
    membership.person.updated_by = membership.person.name
  end

  def email_organizer(status)
    args = { 'attendance_was' => membership.attendance,
             'attendance' => status,
             'organizer_message' => organizer_message }
    EmailOrganizerNoticeJob.perform_later(membership.id, args)
  end

  def log_rsvp(status)
    Rails.logger.info "\n\n*** RSVP: #{membership.person.name}
    (#{membership.person_id}) is now #{status} for
    #{membership.event.code} ***\n\n".squish
  end

  def update_membership(status)
    email_organizer(status)
    log_rsvp(status)
    update_membership_fields(status)
    update_person_fields if status == 'Confirmed'
    membership.sync_remote = true
    membership.save
  end
end
