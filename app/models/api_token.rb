class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "mcp_"

  belongs_to :workspace
  has_many :tool_invocations, dependent: :destroy
  delegate :team, to: :workspace

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.with_invocation_counts(relation, since: 24.hours.ago)
    tokens = relation.to_a
    ids = tokens.map(&:id)
    return tokens if ids.empty?

    counts = ToolInvocation
      .where(api_token_id: ids)
      .where("tool_invocations.created_at >= ?", since)
      .group(:api_token_id)
      .count

    tokens.each do |token|
      token.instance_variable_set(:@invocation_count, counts.fetch(token.id, 0))
    end
    tokens
  end

  # Number of tool invocations for this token since `since`. Uses the count
  # batch-loaded via `with_invocation_counts` when present.
  def invocation_count(since: 24.hours.ago)
    return @invocation_count if @invocation_count

    tool_invocations.where("tool_invocations.created_at >= ?", since).count
  end

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
