class BotAuthorization < ApplicationRecord
  CODE_LENGTH = 6
  REQUEST_TOKEN_LENGTH = 32
  PENDING_TTL = 30.minutes
  CODE_TTL = 5.minutes

  enum :status, {
    pending: 0,
    approved: 1,
    consumed: 2,
    rejected: 3,
    expired: 4
  }

  belongs_to :workspace

  validates :request_token, presence: true, uniqueness: true
  validates :name, presence: true

  scope :pending_active, -> { pending.where("expires_at > ?", Time.current) }

  # Register a bot's request to access a workspace. The caller uses
  # request_token to build the browser URL a signed-in owner opens to decide.
  def self.initiate!(workspace:, name:, justification: nil)
    create!(
      workspace: workspace,
      name: name,
      justification: justification,
      request_token: SecureRandom.base58(REQUEST_TOKEN_LENGTH),
      status: :pending,
      expires_at: Time.current + PENDING_TTL
    )
  end

  # Locate a pending request by its request_token, expiring it if past TTL.
  def self.find_active(token)
    return nil if token.blank?

    find_by(request_token: token, status: :pending).tap do |record|
      record&.expire! if record&.expires_at && record.expires_at <= Time.current
    end
  end

  def owner?(user)
    user == workspace.user
  end

  # Approve the request and mint the one-time verification code. Returns the
  # code (digest stored) for the user to relay to the agent.
  def approve!
    return nil unless pending?

    code = verify_code
    update!(
      status: :approved,
      approved_at: Time.current
    )
    code
  end

  # Regenerate a fresh, still-valid code for an already-approved request (e.g.
  # on a duplicate approve submit). The original code only existed as a digest
  # and can't be re-shown, so we mint a new one. Returns nil unless approved
  # and unexpired.
  def reissue_code!
    return nil unless approved? && approved_at.present? && expires_at > Time.current

    verify_code
  end

  def reject!
    update!(status: :rejected) if pending_active?
  end

  def expire!
    update!(status: :expired) if pending?
  end

  # Redeem an approved request with the code the user relayed to the agent.
  # Returns the raw API token on a valid, unexpired, single-use code; nil if
  # anything is wrong. The record moves to consumed and the code is cleared.
  def redeem!(code)
    return nil unless redeemable?
    return nil unless ApiToken.digest(code.to_s) == code_digest

    raw = ApiToken.issue!(workspace: workspace, name: "bot:#{name}")
    update!(
      status: :consumed,
      issued_at: Time.current,
      code_digest: nil,
      code_expires_at: nil
    )
    raw
  end

  def pending_active?
    pending? && expires_at.present? && expires_at > Time.current
  end

  def redeemable?
    approved? && code_digest.present? && code_expires_at.present? && code_expires_at > Time.current
  end

  private

  def verify_code
    code = format("%0#{CODE_LENGTH}d", SecureRandom.random_number(10**CODE_LENGTH))
    update!(
      code_digest: ApiToken.digest(code),
      code_expires_at: Time.current + CODE_TTL
    )
    code
  end
end
