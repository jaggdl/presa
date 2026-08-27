# frozen_string_literal: true

require "faraday"
require "json"

module Services
  # A Seerr media-management server (Plex/Jellyfin request manager). Tools
  # authenticate with an API key passed as the X-Api-Key header.
  class Seerr < Service
    kind :seerr
    icon "seerr.png"

    config_field :api_key, required: true, secret: true
    config_field :base_url, default: "http://localhost:5055"

    # Seerr's API lives under /api/v1. Prefix paths here so tools can reference
    # them without the version segment.
    API_PREFIX = "/api/v1"

    # Perform a GET against the Seerr API.
    def get(path, headers: {})
      conn.get("#{API_PREFIX}#{path}") do |req|
        req.headers["X-Api-Key"] = config[:api_key]
        headers.each { |key, value| req.headers[key] = value }
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Perform a POST against the Seerr API. `body` is sent as JSON when present.
    def post(path, body: nil, headers: {})
      conn.post("#{API_PREFIX}#{path}") do |req|
        req.headers["X-Api-Key"] = config[:api_key]
        req.headers["Content-Type"] = "application/json"
        headers.each { |key, value| req.headers[key] = value }
        req.body = JSON.generate(body) if body
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Probes connectivity and auth by hitting an authenticated endpoint. Returns
    # true on success, raises with a message on failure.
    def test_connection(config = nil)
      validate_required_config!(config)
      cfg = normalize_config(config)
      base_url = cfg[:base_url].to_s.presence || "http://localhost:5055"

      res = Faraday.get("#{base_url}/api/v1/discover/trending") do |req|
        req.headers["X-Api-Key"] = cfg[:api_key].to_s
      end
      raise "Seerr returned status #{res.status}" unless res.success?

      true
    end

    private

    def conn
      @conn ||= Faraday.new(url: config[:base_url]) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end