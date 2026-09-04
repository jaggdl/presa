# frozen_string_literal: true

module Oauth
  # Base for OAuth provider definitions (Google, Spotify, Strava, ...). Each
  # concrete subclass holds the provider's metadata — its key, authorize/token
  # endpoints, and brand icon — that OAuth services and client credentials
  # compose rather than duplicating. Concrete providers declare their own
  # class-level `kind` scope/behaviours when needed.
  #
  # Providers are also resolvable dynamically: an installed `OpenapiKind`
  # whose spec declares an OAuth scheme registers itself by namespace (e.g.
  # "figma"), so `for_provider` and `OauthClientCredential.icon_for` work for
  # OpenAPI-backed services exactly as they do for the hardcoded providers.
  #
  # Loaded eagerly via Zeitwerk; look up a provider by its key with
  # `Oauth::Base.for_provider`.
  class Base
    class << self
      def key(value = nil)
        @key = value.to_s if value
        @key
      end

      def icon(value = nil)
        @icon = value.to_s if value
        @icon
      end

      def authorize_uri(value = nil)
        @authorize_uri = value.to_s if value
        @authorize_uri
      end

      def token_uri(value = nil)
        @token_uri = value.to_s if value
        @token_uri
      end

      def refresh_uri(value = nil)
        @refresh_uri = value.to_s if value
        @refresh_uri
      end

      def scopes(value = nil)
        @scopes = value if value
        @scopes
      end

      # Resolve the provider for a key (e.g. "google" → Oauth::Google, "figma"
      # → an Oauth::Base::Dynamic built from the installed Figma OpenAPI kind),
      # triggering Zeitwerk autoload for the hardcoded subclasses. Returns nil
      # for unknown providers.
      def for_provider(provider)
        key = provider.to_s
        klass = "Oauth::#{key.camelize}".safe_constantize
        return klass if klass && klass < self

        Dynamic.for_key(key)
      end
    end

    # A provider defined by runtime metadata — the primary OAuth slot of an
    # installed `OpenapiKind` — instead of a hardcoded subclass. Carries the
    # same surface (`authorize_uri`, `token_uri`, `refresh_uri`, `scopes`,
    # `icon`) so the OAuth exchange, authorize-URL builders, and credential
    # icons treat it identically to the checked-in providers. Resolved lazily
    # per key from the kind record, so uninstalling a preset just stops
    # resolving instead of leaving stale metadata behind.
    class Dynamic
      attr_reader :key, :authorize_uri, :token_uri, :refresh_uri, :scopes

      def self.for_key(key)
        kind = ::OpenapiKind.find_by(namespace: key)
        slot = kind&.oauth_slot
        return nil unless slot

        new(key, kind: kind, slot: slot)
      end

      def initialize(key, kind:, slot:)
        @key = key.to_s
        @kind = kind
        @authorize_uri = slot["authorization_url"].to_s
        @token_uri = slot["token_url"].to_s
        @refresh_uri = slot["refresh_url"].to_s.presence
        @scopes = slot["scopes"].is_a?(Hash) ? slot["scopes"] : {}
      end

      # The kind's attached icon (a blob URL the image helpers can render), or
      # the generic placeholder when the kind has none.
      def icon
        return "placeholder.png" unless @kind.icon.attached?

        Rails.application.routes.url_helpers.rails_blob_path(@kind.icon, only_path: true)
      end
    end
  end
end
