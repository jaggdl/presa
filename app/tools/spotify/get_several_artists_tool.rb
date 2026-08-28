# frozen_string_literal: true

module Spotify
  # Several artists based on their Spotify IDs (up to 50).
  class GetSeveralArtistsTool < Base
    description "Get Spotify catalog information for several artists based on their Spotify IDs"

    arguments do
      required(:ids).array(:str?).description("The Spotify IDs of the artists (max 50, comma-separated)")
    end

    def call(ids:)
      spotify_get("artists", params: { ids: ids.join(",") })
    end
  end
end
