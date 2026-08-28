# frozen_string_literal: true

module Oauth
  # Base for OAuth provider definitions (Google, Spotify, Strava, ...). Each
  # concrete subclass holds the provider's metadata — its key, authorize/token
  # endpoints, and brand icon — that OAuth services and client credentials
  # compose rather than duplicating. Concrete providers declare their own
  # class-level `kind` scope/behaviours when needed.
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

      # Resolve the provider subclass for a key (e.g. "google" → Oauth::Google),
      # triggering Zeitwerk autoload. Returns nil for unknown providers.
      def for_provider(provider)
        klass = "Oauth::#{provider.to_s.camelize}".safe_constantize
        klass if klass && klass < self
      end
    end
  end
end
