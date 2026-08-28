# frozen_string_literal: true

module Spotify
  # A playlist owned by a Spotify user.
  class GetPlaylistTool < Base
    description "Get a playlist owned by a Spotify user"

    arguments do
      required(:playlist_id).filled(:string).description("The Spotify ID of the playlist")
      optional(:fields).filled(:string).description("A comma-separated list of the fields to return, e.g. items(name,id)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
      optional(:additional_types).filled(:string).description("A comma-separated list of item types that your client supports besides the default track type. Valid types are: track and episode.")
    end

    def call(playlist_id:, fields: nil, market: nil, additional_types: nil)
      params = {}
      params[:fields] = fields if fields
      params[:market] = market if market
      params[:additional_types] = additional_types if additional_types
      spotify_get("playlists/#{playlist_id}", params: params)
    end
  end
end
