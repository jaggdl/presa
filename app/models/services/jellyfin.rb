# frozen_string_literal: true

require "net/http"

module Services
  class Jellyfin < Service
    kind :jellyfin

    config_field :api_key, required: true, secret: true
    config_field :base_url, default: "http://localhost:8096"

    # Perform a GET against the server. `auth: false` skips the API key header.
    def get(path, headers: {}, auth: true)
      uri = URI("#{config[:base_url]}#{path}")

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["X-Emby-Token"] = config[:api_key] if auth
      headers.each { |key, value| request[key] = value }

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
      JSON.parse(response.body)
    rescue StandardError => e
      { error: e.message }
    end
  end
end
