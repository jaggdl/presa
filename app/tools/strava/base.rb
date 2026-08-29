# frozen_string_literal: true

module Strava
  # Abstract base for all Strava tools. Not exposed directly. HTTP transport
  # and OAuth bearer-token injection live on the service (composed via
  # `Oauth::Client`); this base only shapes requests to the Strava v3 REST API.
  class Base < ApplicationTool
    service_kind :strava
    abstract_tool true

    private

    # GET against the Strava API, returning the parsed JSON body. `path` is
    # relative to the service's API base (e.g. "athlete"); a leading slash
    # would make Faraday drop the base path and hit the marketing site.
    def strava_get(path, params: {})
      service.client.get(path, params: params)
    end
  end
end
