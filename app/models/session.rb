class Session < ApplicationRecord
  belongs_to :user

  SLIDING_IDLE_TIMEOUT = 1.day
  SLIDE_AFTER = 30.minutes
  ROTATE_AFTER = 30.minutes

  before_create :set_initial_expiry

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # True once this session's id is old enough that it should be re-issued so a
  # long-lived/unrotated id can't be replayed indefinitely after collection.
  def rotation_due?
    created_at <= ROTATE_AFTER.ago
  end

  # Sliding expiry: extend the session's lifetime, but only write once it is
  # within SLIDE_AFTER of expiring so activity doesn't hammer the database.
  def slide_expiry!
    return unless expires_at.nil? || expires_at - Time.current < SLIDE_AFTER

    update_columns(expires_at: SLIDING_IDLE_TIMEOUT.from_now)
  end

  private

    def set_initial_expiry
      self.expires_at ||= SLIDING_IDLE_TIMEOUT.from_now
    end
end
