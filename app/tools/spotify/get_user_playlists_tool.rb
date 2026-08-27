# frozen_string_literal: true

module Spotify
  # The playlists owned or followed by the current Spotify user.
  class GetUserPlaylistsTool < Base
    description "Get a list of the playlists owned or followed by the current Spotify user"
    kind "get_user_playlists"

    arguments do
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of playlists to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first playlist to return (default 0)")
    end

    def call(limit: nil, offset: nil)
      params = {}
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("me/playlists", params: params)
    end
  end
end
