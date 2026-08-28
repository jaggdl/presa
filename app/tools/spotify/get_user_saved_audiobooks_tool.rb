# frozen_string_literal: true

module Spotify
  # The audiobooks saved in the current user's "Your Music" library.
  class GetUserSavedAudiobooksTool < Base
    description "Get a list of the audiobooks saved in the current user's Spotify library"

    arguments do
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of audiobooks to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first audiobook to return (default 0)")
    end

    def call(limit: nil, offset: nil)
      params = {}
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("me/audiobooks", params: params)
    end
  end
end
