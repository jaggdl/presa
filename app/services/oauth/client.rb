# frozen_string_literal: true

require "faraday"
require "json"

module Oauth
  # Composed outbound HTTP client for OAuth-backed services. Transport,
  # bearer-token injection, and rate-limit retry live here — on the service,
  # not the tool base — so every OAuth tool family (Gmail, Google Analytics,
  # Google Calendar, Strava, Spotify, ...) stops duplicating a Faraday
  # connection built against its own API base. A service composes a client per
  # API base URL, passing itself as the token source (its `authorized_token`
  # refreshes on demand), and tools just pick the request shape.
  #
  # HTTP 429 rate-limit responses are retried with exponential backoff,
  # honoring the Retry-After header when present. An injectable Faraday
  # `connection` is honored for tests, mirroring `Mcp::Client`.
  class Client
    # How many times a rate-limited request is retried before the body is
    # returned as-is. Backoff starts at 1s (never a tight loop) and caps out.
    MAX_RETRIES = 3
    RETRY_AFTER_CAP = 60

    def initialize(base_url:, token_source:, connection: nil, max_retries: MAX_RETRIES)
      @base_url = base_url
      @token_source = token_source
      @connection = connection
      @max_retries = max_retries
    end

    # GET against the API base URL, returning the parsed JSON body.
    def get(path, params: {})
      request(:get, path, params: params)
    end

    # POST against the API base URL, optionally with a JSON request body and
    # query params. Returns the parsed JSON body.
    def post(path, body: nil, params: {})
      request(:post, path, body: body, params: params)
    end

    # PATCH against the API base URL, sending `body` as JSON. Returns the
    # parsed JSON body.
    def patch(path, body:)
      request(:patch, path, body: body)
    end

    # PUT against the API base URL, optionally with a JSON request body and
    # query params. Returns the parsed JSON body.
    def put(path, body: nil, params: {})
      request(:put, path, body: body, params: params)
    end

    # DELETE against the API base URL.
    def delete(path, params: {})
      request(:delete, path, params: params)
    end

    private

    def request(method, path, body: nil, params: {}, retries: 0)
      response = conn.public_send(method, path) do |req|
        req.headers["Authorization"] = "Bearer #{@token_source.authorized_token}"
        req.params.update(params) if params.any?
        req.headers["Content-Type"] = "application/json" if body
        req.body = JSON.generate(body) if body
      end

      return response.body unless response.status == 429 && retries < @max_retries

      sleep backoff_for(response, retries)
      request(method, path, body: body, params: params, retries: retries + 1)
    end

    # Pause duration before retrying a 429. Honors the Retry-After header
    # (capped), else exponential backoff from 1s.
    def backoff_for(response, retries)
      retry_after = response.headers["retry-after"].to_f
      return [ retry_after, RETRY_AFTER_CAP ].min if retry_after.positive?

      [ (2**retries).clamp(1, RETRY_AFTER_CAP), 1 ].max
    end

    def conn
      @connection ||= Faraday.new(url: @base_url) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    end
  end
end
