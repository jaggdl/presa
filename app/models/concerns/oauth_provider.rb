# frozen_string_literal: true

require "active_support/concern"

# OAuth-backed service behaviour, shared by `OauthService` subclasses (Google
# Calendar, Notion, Strava, ...) and OpenAPI-generated services whose spec declares an
# OAuth scheme (`Services::Openapi`). Unlike plain / MCP services, an
# OAuth-backed service carries no user-typed config fields for auth: the
# OAuth *client* (client_id/secret) lives on an OauthClientCredential, and
# the acquired *grant* (access/refresh tokens) lives on an OauthGrant, both
# associated with the service.
#
# A service is "connected" once it has a grant. `authorized_token` is the
# call-time entry point tools use to obtain a valid access token, refreshing
# it (via the service's grant + client) when an expired one is held.
#
# The provider (endpoints/icon) is resolved through `Oauth::Base` by
# `oauth_provider` — a fixed key declared per service class (Google/Notion),
# or for OpenAPI services derived from the kind's primary OAuth slot.
module OauthProvider
  extend ActiveSupport::Concern

  included do
    class_attribute :oauth_provider, default: nil
    class_attribute :oauth_scope, default: nil

    # The service kind's API base URL for its tools' requests, e.g.
    # "https://www.googleapis.com/calendar/v3". Kinds whose tools hit multiple APIs
    # (Google Analytics' Admin + Data APIs) pass a `base_url:` to `#client`
    # instead of (or in addition to) declaring this.
    class_attribute :oauth_api_base_url, default: nil

    # Extra headers merged into every tool request for this service kind,
    # e.g. Notion's required `Notion-Version` pin. Carried on the composed
    # client so tool bases never repeat them.
    class_attribute :oauth_api_headers, default: {}

    # How the client credentials are presented to the provider's token
    # endpoint: `:form` (Google/Spotify/Strava — client_id/client_secret in
    # the form body) or `:basic` (Notion — an HTTP Basic Authorization header
    # with a JSON body).
    class_attribute :oauth_client_auth, default: :form

    has_one :oauth_grant, foreign_key: :service_id, dependent: :destroy

    # The provider must resolve to a concrete provider definition (its
    # authorize + token endpoints) before a service row can exist. Skipped
    # for service kinds that declare no provider at all (e.g. an OpenAPI
    # kind without an OAuth scheme — those stay manual-credential only).
    validate :provider_configured
  end

  class_methods do
    # The OAuth provider definition for this service's kind, resolved from
    # its declared provider key. Raises if a provider cannot be resolved.
    def provider_class
      Oauth::Base.for_provider(oauth_provider)
    end

    # Builds a provider authorize URL for an arbitrary client credential.
    # Used both for reconnecting an existing service (via `authorize_url`)
    # and for the new-service flow, where no service exists yet.
    def authorize_url_for(client:, redirect_uri:, state:, oauth_provider: nil)
      provider = Oauth::Base.for_provider(oauth_provider || self.oauth_provider)
      raise "OAuth provider not configured" unless provider

      Oauth::Exchange.new.authorize_url(
        uri: provider.authorize_uri,
        client_id: client.client_id,
        redirect_uri: redirect_uri,
        # The client's registered app scopes win when set (providers like
        # Figma reject authorize requests asking for scopes the app isn't
        # configured with); otherwise the kind's declared scope is used.
        scope: client.scope.presence || oauth_scope,
        state: state,
        # OpenAPI-kind providers follow their spec's OAuth flow verbatim;
        # the Google-family extras must not leak into a strict provider's
        # consent URL.
        google_params: !provider.is_a?(Oauth::Base::Dynamic)
      )
    end

    # The class that performs the token round-trips. Overridable in tests to
    # inject a fake exchange.
    def exchange_factory
      Oauth::Exchange
    end
  end

  # The client credential backing this service's grant, or nil.
  def oauth_client_credential
    oauth_grant&.oauth_client_credential
  end

  # The provider name (e.g. "google", or the kind's namespace for OpenAPI
  # services) for this service kind.
  def provider
    oauth_provider_key
  end

  # The OAuth provider key for this *instance* — derived from the class by
  # default. OpenAPI services override it to resolve from their kind (STI
  # instances are the base `Services::Openapi` class, which declares no
  # provider on its own).
  def oauth_provider_key
    self.class.oauth_provider.to_s
  end

  # The composed HTTP client for this service's tools, against the given API
  # base URL (defaulting to the kind's declared `oauth_api_base_url`). Tools
  # use it to issue authorized requests: bearer-token injection and transport
  # live here, resolved from this service's grant at call time and refreshed
  # on demand. Memoized per base URL, so Google-Analytics-style kinds that
  # hit multiple APIs hold one client each.
  def client(base_url: self.class.oauth_api_base_url)
    base = base_url.to_s.presence
    raise ArgumentError, "OAuth API base URL is not configured for #{self.class.kind}" if base.blank?

    @oauth_clients ||= {}
    @oauth_clients[base] ||= Oauth::Client.new(
      base_url: base,
      token_source: self,
      default_headers: self.class.oauth_api_headers
    )
  end

  def connected?
    oauth_grant.present?
  end

  # The provider authorization endpoint for this service kind, resolved from
  # its OAuth provider class.
  def authorize_uri
    provider_class.authorize_uri
  end

  # The provider token endpoint for this service kind, resolved from its
  # OAuth provider class.
  def token_uri
    provider_class.token_uri
  end

  # The OAuth provider definition (Oauth::Google, Oauth::Spotify, a Dynamic
  # for OpenAPI kinds, ...) for this service kind.
  def provider_class
    Oauth::Base.for_provider(oauth_provider_key)
  end

  # The provider authorize URL that bounces the user to consent for this
  # service, using the client credential already linked to its grant. The
  # provider key is resolved per instance and passed explicitly when it
  # differs from the class's own (OpenAPI services are the base STI class,
  # whose class-level provider is nil); subclasses that override
  # `authorize_url_for` with their own signature (e.g. Notion) keep getting
  # exactly their params.
  def authorize_url(redirect_uri:, state:)
    client = oauth_client_credential
    raise "No OAuth client credential connected to this service" unless client

    kwargs = { client: client, redirect_uri: redirect_uri, state: state }
    kwargs[:oauth_provider] = oauth_provider_key if oauth_provider_key != self.class.oauth_provider.to_s
    self.class.authorize_url_for(**kwargs)
  end

  # Exchanges an authorization `code` for token fields without persisting
  # anything. Separate from storing so the controller can create the service
  # only after a successful exchange.
  def exchange_tokens(code:, redirect_uri:, client_credential:)
    exchange.exchange_code(
      token_uri: token_uri,
      code: code,
      client_id: client_credential.client_id,
      client_secret: client_credential.client_secret,
      redirect_uri: redirect_uri,
      client_auth: self.class.oauth_client_auth
    )
  end

  # Applies token fields as this service's grant, bound to
  # `client_credential`. Returns the grant object (already associated but not
  # necessarily saved — the caller saves it, e.g. with a new service).
  def store_grant!(tokens:, client_credential:)
    access = tokens["access_token"]
    raise Oauth::Error, "No access token returned in exchange" if access.blank?

    grant = oauth_grant || build_oauth_grant
    grant.oauth_client_credential = client_credential
    grant.provider = oauth_provider_key
    grant.access_token = access
    grant.refresh_token = tokens["refresh_token"]
    grant.token_type = tokens["token_type"]
    grant.scope = tokens["scope"] || self.class.oauth_scope
    grant.expires_at = time_from_expires_in(tokens["expires_in"])
    # A fresh consent supersedes any prior "needs reconnect" state.
    grant.needs_reconnect = false
    grant.needs_reconnect_at = nil
    grant
  end

  # Exchanges an authorization `code` and persists the grant on this
  # (already persisted) service. Returns true on success.
  def acquire_credentials!(code:, redirect_uri:, client_credential:)
    raise "Service must be persisted" unless persisted?

    store_grant!(
      tokens: exchange_tokens(code: code, redirect_uri: redirect_uri, client_credential: client_credential),
      client_credential: client_credential
    ).save!
    true
  end

  # Returns a valid (non-expired) access token for this service, refreshing
  # the underlying grant first if it is expired. Raises when the grant is
  # missing or cannot be refreshed.
  #
  # A grant already flagged `needs_reconnect` is not retried: its refresh
  # token is known-dead, so we fail fast with the actionable reconnect message
  # rather than hammering the provider on every request.
  def authorized_token
    grant = oauth_grant
    raise Oauth::Error, "OAuth not completed for this service" unless grant
    return grant.access_token unless grant.expired?
    raise reconnect_error(grant) if grant.needs_reconnect?

    refresh_grant!(grant)
  end

  # The human-facing name for this service in reconnect messaging. OpenAPI
  # services carry the spec's title (e.g. "Google Search Console"); static
  # OAuth kinds fall back to their display name (e.g. "Google Calendar").
  def oauth_display_name
    title = respond_to?(:api_title) ? api_title.presence : nil
    title || display_name
  end

  # The actionable message returned to bots and shown in the UI when a service
  # must be reconnected. Never includes provider secrets or raw error bodies.
  def reconnect_message
    "Reconnect #{oauth_display_name} — its authorization has expired or been revoked."
  end

  # Proactively refreshes the grant's access token even while it is still
  # valid, so a refresh token the provider has since revoked is discovered —
  # and the grant flagged — before the next data request needs it. Returns the
  # access token; raises `Oauth::ReconnectRequired` when the grant is dead.
  # Used by the scheduled health probe (RefreshOauthGrantsJob).
  def refresh_oauth_grant!
    grant = oauth_grant
    raise Oauth::Error, "OAuth not completed for this service" unless grant
    return grant.access_token unless grant.refreshable?
    return grant.access_token if grant.needs_reconnect?

    refresh_grant!(grant)
  end

  private

  def provider_configured
    return unless self.class.oauth_provider.present?

    return if provider_class&.authorize_uri.present? && provider_class&.token_uri.present?

    errors.add(:config, "OAuth provider endpoints are not configured")
  end

  def refresh_grant!(grant)
    client = grant.oauth_client_credential
    raise Oauth::Error, "Grant cannot be refreshed; reconnect the service" unless client&.present? && grant.refreshable?

    tokens = exchange.refresh(
      token_uri: token_uri,
      refresh_token: grant.refresh_token,
      client_id: client.client_id,
      client_secret: client.client_secret,
      client_auth: self.class.oauth_client_auth
    )
    new_token = tokens["access_token"].presence
    raise Oauth::Error, "Refresh returned no access token; reconnect the service" if new_token.blank?

    grant.update!(
      access_token: new_token,
      refresh_token: tokens["refresh_token"].presence || grant.refresh_token,
      expires_at: time_from_expires_in(tokens["expires_in"]),
      needs_reconnect: false,
      needs_reconnect_at: nil
    )
    new_token
  rescue Oauth::ReconnectRequired
    # The provider rejected the refresh token: record the explicit state so
    # every later call fails fast with an actionable message instead of
    # echoing the raw provider error. Re-raise enriched with this service's
    # name so bots and the UI can say exactly what to reconnect.
    grant.mark_needs_reconnect! if grant.persisted?
    raise reconnect_error(grant)
  rescue Oauth::Error
    raise
  rescue StandardError => e
    raise Oauth::Error, "Token refresh failed: #{e.message}"
  end

  # Builds the actionable reconnect error for this service's grant.
  def reconnect_error(grant)
    Oauth::ReconnectRequired.new(reconnect_message, provider: oauth_provider_key.presence || grant.provider)
  end

  def exchange
    @exchange ||= self.class.exchange_factory.new
  end

  def time_from_expires_in(expires_in)
    return nil if expires_in.blank?

    Time.current + expires_in.to_i
  end
end
