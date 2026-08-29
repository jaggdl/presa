# frozen_string_literal: true

require "faraday"
require "json"

module Oauth
  # Composed outbound HTTP client for OAuth-backed services. Transport and
  # bearer-token injection live here — on the service, not the tool base — so
  # every OAuth tool family (Gmail, Google Analytics, Google Calendar, Strava,
  # Spotify, ...) stops duplicating a Faraday connection built against its own
  # API base. A service composes a client per API base URL, passing itself as
  # the token source (its `authorized_token` refreshes on demand), and tools
  # just pick the request shape.
  #
  # An injectable Faraday `connection` is honored for tests, mirroring
  # `Mcp::Client`.
  class Client
    def initialize(base_url:, token_source:, connection: nil)
      @base_url = base_url
      @token_source = token_source
      @connection = connection
    end

    # GET against the API base URL, returning the parsed JSON body.
    def get(path, params: {})
      request(:get, path) do |req|
        req.params.update(params) if params.any?
      end.body
    end

    # POST against the API base URL, sending `body` as JSON. Returns the
    # parsed JSON body.
    def post(path, body:)
      request(:post, path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end.body
    end

    # PATCH against the API base URL, sending `body` as JSON. Returns the
    # parsed JSON body.
    def patch(path, body:)
      request(:patch, path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end.body
    end

    # DELETE against the API base URL.
    def delete(path)
      request(:delete, path).body
    end

    private

    def request(method, path, &block)
      conn.send(method, path) do |req|
        req.headers["Authorization"] = "Bearer #{@token_source.authorized_token}"
        block.call(req) if block
      end
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
