# frozen_string_literal: true

module Spotify
  # The shows saved in the current user's Spotify library.
  class GetUserSavedShowsTool < Base
    description "Get a list of shows saved in the current user's Spotify library"

    arguments do
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of shows to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first show to return (default 0)")
    end

    def call(limit: nil, offset: nil)
      params = {}
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("me/shows", params: params)
    end
  end
end
