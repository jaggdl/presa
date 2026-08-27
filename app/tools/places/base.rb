# frozen_string_literal: true

require "faraday"
require "json"

module Places
  # Abstract base for all Google Places API (New) tools. Not exposed directly.
  # Authenticates with the service's API key (X-Goog-Api-Key header) and sends
  # the required X-Goog-FieldMask header, so callers control exactly which
  # place fields are returned (and billed). HTTP 429 rate-limit responses are
  # retried with exponential backoff honoring the Retry-After header.
  class Base < ApplicationTool
    service_kind :places
    abstract_tool true

    PLACES_API = "https://places.googleapis.com/v1"

    # How many times a rate-limited request is retried before the body is
    # returned as-is. Backoff starts at 1s (never a tight loop) and caps out.
    MAX_RETRIES = 3
    RETRY_AFTER_CAP = 60

    # Overridable in tests to inject a fake Faraday connection.
    def conn
      @conn ||= Faraday.new(url: PLACES_API) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    end

    private

    # GET against the Places API, returning the parsed JSON body. `path` is
    # relative to PLACES_API's base (e.g. "places/ChIJ..."`).
    def places_get(path, fields:, params: {})
      request_with_backoff(:get, path, fields: fields, params: params)
    end

    # POST a JSON body against the Places API (e.g. "places:searchText"),
    # returning the parsed JSON body.
    def places_post(path, fields:, body:)
      request_with_backoff(:post, path, fields: fields, body: body)
    end

    def request_with_backoff(method, path, fields:, params: {}, body: nil, retries: 0)
      response = conn.send(method, path) do |req|
        req.headers["X-Goog-Api-Key"] = api_key
        req.headers["X-Goog-FieldMask"] = fields
        req.headers["Content-Type"] = "application/json" if method == :post
        req.params.update(params) if params.any?
        req.body = JSON.generate(body) if body
      end

      return response.body unless response.status == 429 && retries < MAX_RETRIES

      sleep backoff_for(response, retries)
      request_with_backoff(method, path, fields: fields, params: params, body: body, retries: retries + 1)
    end

    # Pause duration before retrying a 429. Honors Retry-After (capped), else
    # exponential backoff from 1s.
    def backoff_for(response, retries)
      retry_after = response.headers["retry-after"].to_f
      return [ retry_after, RETRY_AFTER_CAP ].min if retry_after.positive?

      [ (2**retries).clamp(1, RETRY_AFTER_CAP), 1 ].max
    end

    # The service's Google Maps Platform API key, sent as X-Goog-Api-Key.
    def api_key
      service.config[:api_key]
    end
  end
end
