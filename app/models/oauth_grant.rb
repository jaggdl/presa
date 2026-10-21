# frozen_string_literal: true

# The OAuth *grant* for a Service: the user-provided (and provider-issued)
# access/refresh tokens acquired for a specific service through a specific
# client. One grant per service. Grants are per-account and never shared.
class OauthGrant < ApplicationRecord
  encrypts :access_token, :refresh_token

  belongs_to :service
  belongs_to :oauth_client_credential

  validates :provider, presence: true
  validates :access_token, presence: true

  # Refresh slightly before the token truly expires to avoid a doomed request.
  REFRESH_LEEWAY = 30.seconds

  # True when the access token has (or is about to) expire and so should be
  # refreshed before use. A nil expires_at means the provider issued a
  # non-rotating token (e.g. a long-lived integration token that never
  # expires), which is treated as not expired — those kinds are also not
  # refreshable.
  def expired?
    expires_at.present? && expires_at <= Time.current + REFRESH_LEEWAY
  end

  # True when we hold a refresh token capable of restoring a fresh access token.
  def refreshable?
    refresh_token.present?
  end
end
