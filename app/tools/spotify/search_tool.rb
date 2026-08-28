# frozen_string_literal: true

module Spotify
  # Catalog items (albums, artists, playlists, tracks, shows, episodes or
  # audiobooks) that match a keyword search query.
  class SearchTool < Base
    description "Search the Spotify catalog for albums, artists, playlists, tracks, shows, episodes or audiobooks"

    arguments do
      required(:q).filled(:string).description("Your search query; field filters such as album, artist, track, year, upc, isrc and genre are supported")
      required(:type).array(:str?, included_in?: %w[album artist playlist track show episode audiobook]).description("A comma-separated list of item types to search across (album, artist, playlist, track, show, episode, audiobook)")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code; only content available in that market is returned")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("The maximum number of results to return in each item type (default 5)")
      optional(:offset).filled(:integer, gteq?: 0).description("The index of the first result to return (default 0)")
    end

    def call(q:, type:, market: nil, limit: nil, offset: nil)
      params = { q: q, type: type.join(",") }
      params[:market] = market if market
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("search", params: params)
    end
  end
end
