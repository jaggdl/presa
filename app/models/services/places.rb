# frozen_string_literal: true

require "faraday"
require "json"

module Services
  # Google Places API (New), an API-key backed service. Unlike the OAuth
  # services it needs no user grant: the user pastes a Google Maps Platform
  # API key and Presa exposes Text Search, Place Details, and Place Photos
  # tools against https://places.googleapis.com/v1. Requires the Places API
  # (New) to be enabled and billed on the Google Cloud project's Maps service.
  class Places < Service
    kind :places
    icon "places.png"
    category :knowledge

    config_field :api_key, required: true, secret: true

    PLACES_API = "https://places.googleapis.com/v1"

    # Probes connectivity and auth with the cheapest request: a Text Search for
    # a single result requesting only the free ID-only field. Returns true on
    # success, raises with a message on failure.
    def test_connection(config = nil)
      validate_required_config!(config)
      cfg = normalize_config(config)

      res = Faraday.post("#{PLACES_API}/places:searchText") do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["X-Goog-Api-Key"] = cfg[:api_key].to_s
        req.headers["X-Goog-FieldMask"] = "places.id"
        req.body = JSON.generate(textQuery: "test", pageSize: 1)
      end
      raise "Google Places returned status #{res.status}: #{error_snippet(res.body)}" unless res.success?

      true
    end

    private

    # Short, safe prefix of a non-2xx body (never the full payload).
    def error_snippet(body)
      text = body.is_a?(String) ? body.strip : body.to_s
      text = text[0, 300]
      text.empty? ? "no response body" : text
    end
  end
end
