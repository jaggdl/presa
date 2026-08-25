class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "mcp_"

  belongs_to :workspace
  delegate :user, to: :workspace

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.issue!(workspace:, name: nil, expires_at: nil)
    raw = "#{TOKEN_PREFIX}#{SecureRandom.base58(32)}"
    create!(workspace: workspace, name: name, expires_at: expires_at, token_digest: digest(raw))
    raw
  end

  def self.find_active_by_token(raw)
    return nil if raw.blank?

    token = find_by(token_digest: digest(raw), revoked_at: nil)
    return nil if token.nil? || token.expired?

    token.update_columns(last_used_at: Time.current)
    token
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end
end
