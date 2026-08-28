# frozen_string_literal: true

module Spotify
  # Albums belonging to an artist, optionally filtered by album type.
  class GetArtistAlbumsTool < Base
    description "Get Spotify catalog information about an artist's albums"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the artist")
      optional(:include_groups).array(:str?, included_in?: %w[album single appears_on compilation]).description("A list of keywords to filter the response by: album, single, appears_on, or compilation")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 10).description("The maximum number of items to return (default 20, min 1, max 10)")
      optional(:offset).filled(:integer, gteq?: 0).description("The index of the first item to return (default 0)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code")
    end

    def call(id:, include_groups: nil, limit: nil, offset: nil, market: nil)
      params = {}
      params[:include_groups] = include_groups.join(",") if include_groups
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      params[:market] = market if market
      spotify_get("artists/#{id}/albums", params: params)
    end
  end
end
