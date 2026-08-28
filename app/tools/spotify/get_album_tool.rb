# frozen_string_literal: true

module Spotify
  # A single album's catalog information by its Spotify ID.
  class GetAlbumTool < Base
    description "Get an album by its Spotify ID"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the album")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
    end

    def call(id:, market: nil)
      params = {}
      params[:market] = market if market
      spotify_get("albums/#{id}", params: params)
    end
  end
end
