# frozen_string_literal: true

require "faraday"
require "json"

module Strava
  # Abstract base for all Strava tools. Not exposed directly. Resolves the
  # bound OAuth service's live access token (refreshing it if needed) and
  # issues authorized requests against the Strava v3 REST API.
  class Base < ApplicationTool
    service_kind :strava
    abstract_tool true

    STRAVA_API = "https://www.strava.com"

    # Overridable in tests to inject a fake Faraday connection.
    def conn
      @conn ||= Faraday.new(url: STRAVA_API) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    end

    private

    # GET against the Strava API, returning the parsed JSON body.
    def strava_get(path, params: {})
      conn.get(path) do |req|
        req.headers["Authorization"] = "Bearer #{authorized_token}"
        req.params.update(params)
      end.body
    end

    def authorized_token
      service.authorized_token
    end
  end
end
