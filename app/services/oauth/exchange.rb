# frozen_string_literal: true

require "faraday"
require "json"
require "uri"

module Oauth
  # Raised on OAuth token/refresh failures that aren't a redirect-worthy prompt.
  class Error < StandardError; end

  # Builds provider authorize URLs and performs the token endpoint calls
  # (code→tokens exchange and refresh_token→access_token). Hand-rolled on
  # Faraday, mirroring the codebase's `Mcp::Client`.
  #
  # The provider's authorize/token URIs are passed in by the caller (each
  # OAuth service declares its own); client credentials come from an
  # OauthClientCredential. This class holds only the protocol mechanics.
  # An optional Faraday `connection` may be injected for testing.
  class Exchange
    def initialize(connection: nil)
      @connection = connection
    end
    # The URL to bounce the browser to for user consent.
    def authorize_url(uri:, client_id:, redirect_uri:, scope:, state:)
      params = {
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scope,
        state: state,
        access_type: "offline",
        prompt: "consent"
      }
      "#{uri}?#{URI.encode_www_form(params)}"
    end

    # Exchange an authorization `code` for an access (and refresh) token.
    # Returns a hash of token fields: {access_token, refresh_token, token_type,
    # scope, expires_in} (absent keys omitted).
    def exchange_code(token_uri:, code:, client_id:, client_secret:, redirect_uri:)
      post_tokens(token_uri, grant_type: "authorization_code", code: code,
                             client_id: client_id, client_secret: client_secret,
                             redirect_uri: redirect_uri)
    end

    # Refresh an expired access token. Returns the same shape as
    # `exchange_code` (refresh_token may be absent/blank).
    def refresh(token_uri:, refresh_token:, client_id:, client_secret:)
      post_tokens(token_uri, grant_type: "refresh_token", refresh_token: refresh_token,
                             client_id: client_id, client_secret: client_secret)
    end

    private

    def conn(token_uri)
      @connection || Faraday.new(url: token_uri) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 15
        f.options.open_timeout = 10
      end
    end

    def post_tokens(token_uri, params)
      response = conn(token_uri).post("", URI.encode_www_form(params)) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.headers["Accept"] = "application/json"
      end

      body = parse(response.body)
      unless response.success?
        raise Error, "OAuth token request failed (#{response.status}): #{sanitize(body)}"
      end

      body.slice("access_token", "refresh_token", "token_type", "scope", "expires_in")
    end

    def parse(body)
      return {} unless body.is_a?(String) && body.strip.present?

      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end

    # Short, safe prefix of a non-2xx body, never raw secrets.
    def sanitize(body)
      text = body.is_a?(String) ? body.strip : body.to_s
      text = text[0, 300]
      text.empty? ? "no response body" : text
    end
  end
end
