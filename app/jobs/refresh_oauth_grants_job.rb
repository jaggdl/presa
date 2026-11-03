# frozen_string_literal: true

# Lightweight OAuth health probe. Runs on a short schedule (see
# config/recurring.yml) and proactively refreshes every grant whose access
# token is about to expire — even before it is needed by a data request.
#
# This is the early-warning system for the failure mode that matters: a
# refresh token the provider has expired or revoked (e.g. a Google OAuth
# client left on the "Testing" publishing status, whose refresh tokens die
# after 7 days). Instead of discovering it mid-query, the refresh attempt
# fails here and `OauthProvider#refresh_grant!` flips the grant into the
# explicit `needs_reconnect` state, so the next tool call returns an
# actionable "Reconnect ..." message.
#
# It deliberately logs only service ids and non-secret error text, and never
# raises: one dead grant must not stop the others from being refreshed.
class RefreshOauthGrantsJob < ApplicationJob
  queue_as :default

  # How far ahead of expiry to refresh. Google access tokens live ~1 hour, and
  # the schedule runs every 15 minutes, so this guarantees at least one
  # proactive attempt per token before it is actually needed.
  LEAD_TIME = 15.minutes

  def perform
    OauthGrant
      .where(needs_reconnect: false)
      .where("expires_at IS NOT NULL AND expires_at <= ?", LEAD_TIME.from_now)
      .includes(:service)
      .find_each do |grant|
        service = grant.service
        next unless service.respond_to?(:refresh_oauth_grant!)

        service.refresh_oauth_grant!
      rescue Oauth::ReconnectRequired => e
        # Already flagged by the refresh path; make it visible in the log.
        Rails.logger.warn("OAuth health: #{e.message} (service_id=#{grant.service_id})")
      rescue StandardError => e
        Rails.logger.warn("OAuth refresh failed for service_id=#{grant.service_id}: #{e.message}")
      end
  end
end
