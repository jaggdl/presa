module Authenticatable
  extend ActiveSupport::Concern

  MAX_FAILED_LOGIN_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes

  # Burned against bcrypt when an email address doesn't match a user so that
  # unknown vs known-account responses take the same time (email enumeration).
  DUMMY_PASSWORD_DIGEST = BCrypt::Password.create("dummy-password-for-timing",
    cost: BCrypt::Engine.cost).to_s.freeze

  included do
    has_secure_password
  end

  class_methods do
    # Attempts a sign-in with one bcrypt compare regardless of whether the email
    # exists. Returns [ :success, user ], [ :locked, user ], or [ :failure, user ]
    # (a throwaway dummy record for unknown emails). On success the failed-attempt
    # counter is reset.
    def attempt_login(email_address, password)
      user = find_by(email_address: email_address) || new(password_digest: DUMMY_PASSWORD_DIGEST)
      return [ :locked, user ] if user.locked_out?
      return [ :failure, user ] unless user.authenticate(password)

      user.reset_failed_login_attempts! if user.persisted?
      [ :success, user ]
    end
  end

  def locked_out?
    locked_until.present? && locked_until.future?
  end

  # Records a failed password attempt, locking the account (with an extending
  # lockout while attacks keep coming) once the threshold is reached.
  def register_failed_login!
    attempts = failed_login_attempts + 1
    return update_columns(failed_login_attempts: attempts) if attempts < self.class::MAX_FAILED_LOGIN_ATTEMPTS

    locked_until = if self.locked_until.present? && self.locked_until.future?
                     self.locked_until + self.class::LOCKOUT_DURATION
    else
                     self.class::LOCKOUT_DURATION.from_now
    end
    update_columns(failed_login_attempts: attempts, locked_until: locked_until)
  end

  def reset_failed_login_attempts!
    return if failed_login_attempts.zero? && locked_until.nil?

    update_columns(failed_login_attempts: 0, locked_until: nil)
  end
end
