# frozen_string_literal: true

module Spotify
  # Abstract base for all Spotify tools. Not exposed directly. HTTP transport,
  # OAuth bearer-token injection, and 429 rate-limit retry live on the service
  # (composed via `Oauth::Client`); this base only shapes requests to the
  # Spotify Web API.
  class Base < ApplicationTool
    service_kind :spotify
    abstract_tool true

    private

    # GET against the Spotify API, returning the parsed JSON body. `path` is
    # relative to the service's API base (e.g. "me"); a leading slash would
    # make Faraday drop the base path and hit the marketing site.
    def spotify_get(path, params: {})
      service.client.get(path, params: params)
    end

    # PUT against the Spotify API, optionally with a JSON request body and
    # query params (e.g. transfer playback, start/pause/seek/volume/shuffle
    # and repeat commands). Like spotify_get, `path` is relative to the base.
    def spotify_put(path, params: {}, body: nil)
      service.client.put(path, params: params, body: body)
    end

    # POST against the Spotify API, optionally with a JSON request body and
    # query params (e.g. next/previous and add-to-queue commands).
    def spotify_post(path, params: {}, body: nil)
      service.client.post(path, params: params, body: body)
    end
  end
end
