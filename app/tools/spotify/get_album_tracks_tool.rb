# frozen_string_literal: true

module Spotify
  # An album's tracks, optionally limited and offset for paging.
  class GetAlbumTracksTool < Base
    description "Get the tracks of an album, optionally paged"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the album")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of items to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first item to return (default 0)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
    end

    def call(id:, limit: nil, offset: nil, market: nil)
      params = {}
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      params[:market] = market if market
      spotify_get("albums/#{id}/tracks", params: params)
    end
  end
end
