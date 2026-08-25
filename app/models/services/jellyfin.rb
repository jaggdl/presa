# frozen_string_literal: true

require "faraday"
require "json"

module Services
  class Jellyfin < Service
    kind :jellyfin

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
