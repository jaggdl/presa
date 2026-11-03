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
  # non-rotating token (e.g. Notion, whose integration tokens never expire),
  # which is treated as not expired — those kinds are also not refreshable.
  def expired?
    expires_at.present? && expires_at <= Time.current + REFRESH_LEEWAY
  end

  # True when we hold a refresh token capable of restoring a fresh access token.
  def refreshable?
    refresh_token.present?
  end

  # True when the provider has rejected this grant's refresh token (it expired
  # or was revoked). Such a grant can only be restored by reconnecting the
  # service through the OAuth flow; retrying a refresh is pointless and its
  # raw error must never be surfaced as if it were transient.
  def needs_reconnect?
    needs_reconnect
  end

  # Flips the grant into the explicit "needs reconnect" state. Idempotent, so
  # repeated failed probes don't keep rewriting the row; `updated_at` stays
  # meaningful as the last time a refresh was attempted.
  def mark_needs_reconnect!
    return if needs_reconnect?

    update!(needs_reconnect: true, needs_reconnect_at: Time.current)
  end

  # Clears the "needs reconnect" state, e.g. after a successful reconnect
  # stored a fresh grant or a later refresh finally succeeded.
  def clear_needs_reconnect!
    update!(needs_reconnect: false, needs_reconnect_at: nil) if needs_reconnect?
  end
end
