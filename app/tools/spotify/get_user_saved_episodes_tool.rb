# frozen_string_literal: true

module Spotify
  # The episodes saved in the current user's Spotify library.
  class GetUserSavedEpisodesTool < Base
    description "Get a list of the episodes saved in the current user's Spotify library"

    arguments do
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of episodes to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first episode to return (default 0)")
    end

    def call(market: nil, limit: nil, offset: nil)
      params = {}
      params[:market] = market if market
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("me/episodes", params: params)
    end
  end
end
