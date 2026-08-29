# frozen_string_literal: true

# STI base for OAuth-backed services (e.g. Gmail). Unlike plain / MCP
# services, an OAuth service carries no user-typed config fields in the form:
# the OAuth *client* (client_id/secret) lives on an OauthClientCredential,
# and the acquired *grant* (access/refresh tokens) lives on an OauthGrant,
# both associated with the service.
#
# A service is "connected" once it has a grant. `authorized_token` is the
# call-time entry point tools use to obtain a valid access token, refreshing
# it (via the service's grant + client) when an expired one is held.
#
# Concrete providers subclass this and fill in the provider key. Provider
# endpoints/icon are composed from the matching Oauth::Base subclass.
class OauthService < Service
  class_attribute :oauth_provider, default: nil
  class_attribute :oauth_scope, default: nil

  # The service kind's API base URL for its tools' requests, e.g.
  # "https://gmail.googleapis.com". Kinds whose tools hit multiple APIs (Google
  # Analytics' Admin + Data APIs) pass a `base_url:` to `#client` instead of
  # (or in addition to) declaring this.
  class_attribute :oauth_api_base_url, default: nil

  tags :oauth

  has_one :oauth_grant, foreign_key: :service_id, dependent: :destroy

  validate :provider_configured

  # The client credential backing this service's grant, or nil.
  def oauth_client_credential
    oauth_grant&.oauth_client_credential
  end

  # The provider name (e.g. "google") for this service kind.
  def provider
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
    @oauth_clients[base] ||= Oauth::Client.new(base_url: base, token_source: self)
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

  # The OAuth provider definition (Oauth::Google, Oauth::Spotify, ...) for
  # this service kind.
  def provider_class
    self.class.provider_class
  end

  # The OAuth provider definition for this service's kind, resolved from its
  # declared provider key. Raises if a provider cannot be resolved.
  def self.provider_class
    Oauth::Base.for_provider(oauth_provider)
  end

  # The provider authorize URL that bounces the user to consent for this
  # service, using the client credential already linked to its grant.
  def authorize_url(redirect_uri:, state:)
    client = oauth_client_credential
    raise "No OAuth client credential connected to this service" unless client

    self.class.authorize_url_for(client: client, redirect_uri: redirect_uri, state: state)
  end

  # Builds a provider authorize URL for an arbitrary client credential. Used
  # both for reconnecting an existing service (via `authorize_url`) and for
  # the new-service flow, where no service exists yet.
  def self.authorize_url_for(client:, redirect_uri:, state:)
    provider = Oauth::Base.for_provider(oauth_provider)
    raise "OAuth provider not configured" unless provider

    Oauth::Exchange.new.authorize_url(
      uri: provider.authorize_uri,
      client_id: client.client_id,
      redirect_uri: redirect_uri,
      scope: oauth_scope,
      state: state
    )
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
      redirect_uri: redirect_uri
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
    grant.provider = self.class.oauth_provider.to_s
    grant.access_token = access
    grant.refresh_token = tokens["refresh_token"]
    grant.token_type = tokens["token_type"]
    grant.scope = tokens["scope"] || self.class.oauth_scope
    grant.expires_at = time_from_expires_in(tokens["expires_in"])
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
  def authorized_token
    grant = oauth_grant
    raise Oauth::Error, "OAuth not completed for this service" unless grant
    return grant.access_token unless grant.expired?

    refresh_grant!(grant)
  end

  # Probes connectivity by obtaining a valid access token for the stored
  # grant (refreshing it if needed). Returns true on success, raises with a
  # message on failure. Unlike API-key services, there is no form `config`
  # to test against — connectivity is about the acquired grant.
  def test_connection(_config = nil)
    authorized_token
    true
  end

  private

  def provider_configured
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
      client_secret: client.client_secret
    )
    new_token = tokens["access_token"].presence
    raise Oauth::Error, "Refresh returned no access token; reconnect the service" if new_token.blank?

    grant&.update!(
      access_token: new_token,
      refresh_token: tokens["refresh_token"].presence || grant.refresh_token,
      expires_at: time_from_expires_in(tokens["expires_in"])
    )
    new_token
  rescue Oauth::Error
    raise
  rescue StandardError => e
    raise Oauth::Error, "Token refresh failed: #{e.message}"
  end

  def exchange
    @exchange ||= self.class.exchange_factory.new
  end

  # The class that performs the token round-trips. Overridable in tests to
  # inject a fake exchange.
  def self.exchange_factory
    Oauth::Exchange
  end

  def time_from_expires_in(expires_in)
    return nil if expires_in.blank?

    Time.current + expires_in.to_i
  end
end
