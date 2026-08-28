# frozen_string_literal: true

module Spotify
  # The albums saved in the current user's "Your Music" library.
  class GetUserSavedAlbumsTool < Base
    description "Get a list of the albums saved in the current user's Spotify library"

    arguments do
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of items to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first item to return (default 0)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
    end

    def call(limit: nil, offset: nil, market: nil)
      params = {}
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      params[:market] = market if market
      spotify_get("me/albums", params: params)
    end
  end
end
