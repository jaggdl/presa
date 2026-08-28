# frozen_string_literal: true

module Spotify
  # Catalog information for multiple tracks based on their Spotify IDs.
  class GetSeveralTracksTool < Base
    description "Get catalog information for multiple tracks based on their Spotify IDs"

    arguments do
      required(:ids).array(:str?).description("A comma-separated list of the Spotify IDs for the tracks. Maximum: 50 IDs.")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
    end

    def call(ids:, market: nil)
      params = { ids: ids.join(",") }
      params[:market] = market if market
      spotify_get("tracks", params: params)
    end
  end
end
