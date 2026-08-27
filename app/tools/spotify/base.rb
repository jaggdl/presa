# frozen_string_literal: true

require "faraday"
require "json"

module Spotify
  # Abstract base for all Spotify tools. Not exposed directly. Resolves the
  # bound OAuth service's live access token (refreshing it if needed) and
  # issues authorized requests against the Spotify Web API. HTTP 429
  # rate-limit responses are retried with exponential backoff, honoring the
  # Retry-After header when present.
  class Base < ApplicationTool
    service_kind :spotify
    abstract_tool true

    SPOTIFY_API = "https://api.spotify.com/v1"

    # How many times a rate-limited request is retried before the body is
    # returned as-is. Exponential backoff starts at 1s (as the spec requires us
    # not to retry in a tight loop) and caps at RETRY_AFTER_CAP.
    MAX_RETRIES = 3
    RETRY_AFTER_CAP = 60

    # Overridable in tests to inject a fake Faraday connection.
    def conn
      @conn ||= Faraday.new(url: SPOTIFY_API) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    end

    private

    # GET against the Spotify API, returning the parsed JSON body. `path` is
    # relative to SPOTIFY_API's base (e.g. "me"); a leading slash would make
    # Faraday drop the base path and hit the marketing site.
    def spotify_get(path, params: {})
      request_with_backoff(:get, path, params: params)
    end

    def request_with_backoff(method, path, params:, retries: 0)
      response = conn.send(method, path) do |req|
        req.headers["Authorization"] = "Bearer #{authorized_token}"
        req.params.update(params) if params.any?
      end

      return response.body unless response.status == 429 && retries < MAX_RETRIES

      sleep backoff_for(response, retries)
      request_with_backoff(method, path, params: params, retries: retries + 1)
    end

    # Pause duration before retrying a 429. Honors the Retry-After header
    # (capped), else exponential backoff from 1s.
    def backoff_for(response, retries)
      retry_after = response.headers["retry-after"].to_f
      return [ retry_after, RETRY_AFTER_CAP ].min if retry_after.positive?

      [ (2**retries).clamp(1, RETRY_AFTER_CAP), 1 ].max
    end

    def authorized_token
      service.authorized_token
    end
  end
end
