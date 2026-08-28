# frozen_string_literal: true

module Spotify
  # The items of a playlist owned by a Spotify user.
  class GetPlaylistItemsTool < Base
    description "Get full details of the items of a playlist owned by a Spotify user"

    arguments do
      required(:playlist_id).filled(:string).description("The Spotify ID of the playlist")
      optional(:fields).filled(:string).description("A comma-separated list of the fields to return, e.g. items(added_at,added_by.id)")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of items to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first item to return (default 0)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
      optional(:additional_types).filled(:string).description("A comma-separated list of item types that your client supports besides the default track type. Valid types are: track and episode.")
    end

    def call(playlist_id:, fields: nil, limit: nil, offset: nil, market: nil, additional_types: nil)
      params = {}
      params[:fields] = fields if fields
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      params[:market] = market if market
      params[:additional_types] = additional_types if additional_types
      spotify_get("playlists/#{playlist_id}/items", params: params)
    end
  end
end
