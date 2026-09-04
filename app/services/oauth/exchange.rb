# frozen_string_literal: true

require "base64"
require "faraday"
require "json"
require "uri"

module Oauth
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
    # The URL to bounce the browser to for user consent. The Google-style
    # `access_type=offline` + `prompt=consent` extras are sent by default (they
    # coax a refresh token from the Google/Spotify/Strava family); providers
    # that reject unknown params (e.g. OpenAPI kinds whose spec's OAuth flow is
    # strict) opt out with `google_params: false` and get only the standard
    # authorization-code params.
    def authorize_url(uri:, client_id:, redirect_uri:, scope:, state:, google_params: true)
      params = {
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scope,
        state: state
      }
      params = params.merge(access_type: "offline", prompt: "consent") if google_params
      "#{uri}?#{URI.encode_www_form(params)}"
    end

    # Exchange an authorization `code` for an access (and refresh) token.
    # Returns a hash of token fields: {access_token, refresh_token, token_type,
    # scope, expires_in} (absent keys omitted). `client_auth` selects how the
    # client credentials are presented: `:form` (the Google/Spotify/Strava
    # convention — client_id/client_secret in the form body) or `:basic`, used
    # by Notion, which demands them in an HTTP Basic Authorization header and a
    # JSON body.
    def exchange_code(token_uri:, code:, client_id:, client_secret:, redirect_uri:, client_auth: :form)
      params = { grant_type: "authorization_code", code: code, redirect_uri: redirect_uri }
      post_tokens(token_uri, params, client_id: client_id, client_secret: client_secret, client_auth: client_auth)
    end

    # Refresh an expired access token. Returns the same shape as
    # `exchange_code` (refresh_token may be absent/blank).
    def refresh(token_uri:, refresh_token:, client_id:, client_secret:, client_auth: :form)
      params = { grant_type: "refresh_token", refresh_token: refresh_token }
      post_tokens(token_uri, params, client_id: client_id, client_secret: client_secret, client_auth: client_auth)
    end

    private

    def conn(token_uri)
      @connection || Faraday.new(url: token_uri) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 15
        f.options.open_timeout = 10
      end
    end

    def post_tokens(token_uri, params, client_id:, client_secret:, client_auth:)
      headers = { "Accept" => "application/json" }
      body =
        if client_auth == :basic
          headers["Content-Type"] = "application/json"
          headers["Authorization"] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
          JSON.generate(params)
        else
          headers["Content-Type"] = "application/x-www-form-urlencoded"
          URI.encode_www_form(params.merge(client_id: client_id, client_secret: client_secret))
        end

      response = conn(token_uri).post("", body) do |req|
        req.headers.update(headers)
      end

      parsed = parse(response.body)
      unless response.success?
        raise Error, "OAuth token request failed (#{response.status}): #{sanitize(response.body)}"
      end

      parsed.slice("access_token", "refresh_token", "token_type", "scope", "expires_in")
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
