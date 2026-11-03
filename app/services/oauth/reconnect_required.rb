# frozen_string_literal: true

module Oauth
  # Raised when the provider rejects the *stored* grant — its refresh token has
  # expired or been revoked (`invalid_grant`, `invalid_token`, `expired_token`).
  # Unlike a transient failure, this cannot be recovered automatically: a human
  # must reconnect the service through the OAuth flow so a fresh grant is
  # stored. Carries the offending provider so callers can render an actionable
  # "Reconnect ..." message instead of the provider's raw error body.
  #
  # Own file (not folded into error.rb) so Zeitwerk can autoload it by name
  # from the job/controller rescue clauses that reference it directly.
  class ReconnectRequired < Error
    attr_reader :provider

    def initialize(message = nil, provider: nil)
      @provider = provider
      super(message.presence || "Reconnection required")
    end
  end
end
