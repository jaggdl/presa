# frozen_string_literal: true

require "faraday"
require "json"

module Services
  # A Strava integration backed by the v3 REST API
  # (https://developers.strava.com/docs/reference/).
  #
  # Strava uses OAuth 2.0 with short-lived access tokens (~6h) and long-lived
  # refresh tokens. The service stores the user's client_id, client_secret and
  # initial refresh_token; every API call negotiates a fresh access token
  # transparently via Rails.cache (one POST to /oauth/token when the cached
  # token has expired).
  class Strava < Service
    kind :strava
    icon "strava.png"

    config_field :client_id, required: true
    config_field :client_secret, required: true, secret: true
    config_field :refresh_token, required: true, secret: true

    STRAVA_API_BASE = "https://www.strava.com/api/v3"
    STRAVA_OAUTH_TOKEN = "https://www.strava.com/oauth/token"

    # Perform a GET against the Strava API. Token refresh is handled
    # transparently when the cached access token has expired.
    def get(path, headers: {})
      conn.get("#{STRAVA_API_BASE}#{path}") do |req|
        req.headers["Authorization"] = "Bearer #{valid_access_token}"
        headers.each { |k, v| req.headers[k] = v }
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Perform a POST against the Strava API.
    def post(path, body: nil, headers: {})
      conn.post("#{STRAVA_API_BASE}#{path}") do |req|
        req.headers["Authorization"] = "Bearer #{valid_access_token}"
        req.headers["Content-Type"] = "application/json"
        headers.each { |k, v| req.headers[k] = v }
        req.body = JSON.generate(body) if body
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Probes connectivity by hitting the authenticated athlete endpoint.
    # Returns true on success, raises with a message on failure.
    def test_connection(config = nil)
      validate_required_config!(config)
      cfg = normalize_config(config)

      token = fetch_fresh_access_token(cfg)
      res = Faraday.get("#{STRAVA_API_BASE}/athlete") do |req|
        req.headers["Authorization"] = "Bearer #{token}"
      end
      raise "Strava returned status #{res.status}" unless res.success?

      true
    end

    private

    # Returns a valid access token, refreshing via the OAuth endpoint when
    # the cached one is missing or expired.
    def valid_access_token
      cached = Rails.cache.read(cache_key(:access_token))
      expires = Rails.cache.read(cache_key(:expires_at))
      return cached if cached && expires && Time.current < Time.iso8601(expires)

      fetch_and_cache_access_token
    end

    # Hits the Strava OAuth token endpoint with a grant_type=refresh_token
    # request and caches the result.
    def fetch_and_cache_access_token
      token_data = fetch_fresh_access_token(config)
      Rails.cache.write(cache_key(:access_token), token_data[:access_token],
                        expires_in: token_data[:expires_in])
      expires_at = Time.current + token_data[:expires_in]
      Rails.cache.write(cache_key(:expires_at), expires_at.iso8601,
                        expires_in: token_data[:expires_in])
      token_data[:access_token]
    end

    # Refreshes the access token from the OAuth endpoint, returning a hash
    # with :access_token and :expires_in. Accepts an explicit config hash so
    # test_connection can supply its own.
    def fetch_fresh_access_token(cfg = config)
      resp = Faraday.post(STRAVA_OAUTH_TOKEN) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(
          client_id: cfg[:client_id].to_s,
          client_secret: cfg[:client_secret].to_s,
          grant_type: "refresh_token",
          refresh_token: cfg[:refresh_token].to_s
        )
      end
      raise "Strava OAuth returned status #{resp.status}" unless resp.success?

      body = JSON.parse(resp.body)
      { access_token: body["access_token"], expires_in: body["expires_in"] }
    rescue JSON::ParserError => e
      raise "Strava OAuth response could not be parsed: #{e.message}"
    end

    def cache_key(key)
      "strava_#{id}_#{key}"
    end

    def conn
      @conn ||= Faraday.new do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end