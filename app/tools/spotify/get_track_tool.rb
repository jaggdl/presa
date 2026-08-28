# frozen_string_literal: true

module Spotify
  # A single track's catalog information by its Spotify ID.
  class GetTrackTool < Base
    description "Get a track by its Spotify ID"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the track")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
    end

    def call(id:, market: nil)
      params = {}
      params[:market] = market if market
      spotify_get("tracks/#{id}", params: params)
    end
  end
end
