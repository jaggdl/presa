# frozen_string_literal: true

require "faraday"
require "json"

module Services
  class Jellyfin < Service
    kind :jellyfin
    icon "jellyfin.png"
    category :media

    config_field :api_key, required: true, secret: true
    config_field :base_url, default: "http://localhost:8096"

    # Perform a GET against the server. `auth: false` skips the API key header.
    def get(path, headers: {}, auth: true)
      conn.get(path) do |req|
        req.headers["X-Emby-Token"] = config[:api_key] if auth
        headers.each { |key, value| req.headers[key] = value }
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Perform a POST against the server. `body` is sent as JSON when present.
    def post(path, body: nil, headers: {}, auth: true)
      conn.post(path) do |req|
        req.headers["X-Emby-Token"] = config[:api_key] if auth
        headers.each { |key, value| req.headers[key] = value }
        req.body = JSON.generate(body) if body
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Perform a DELETE against the server.
    def delete(path, headers: {}, auth: true)
      conn.delete(path) do |req|
        req.headers["X-Emby-Token"] = config[:api_key] if auth
        headers.each { |key, value| req.headers[key] = value }
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    # Probes connectivity and auth by hitting the authenticated system info
    # endpoint. Returns true on success, raises with a message on failure.
    def test_connection(config = nil)
      validate_required_config!(config)
      cfg = normalize_config(config)
      base_url = cfg[:base_url].to_s.presence || "http://localhost:8096"

      res = Faraday.post("#{base_url}/System/Info") do |req|
        req.headers["X-Emby-Token"] = cfg[:api_key].to_s
      end
      raise "Jellyfin returned status #{res.status}" unless res.success?

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
