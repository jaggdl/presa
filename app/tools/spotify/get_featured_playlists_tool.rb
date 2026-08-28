# frozen_string_literal: true

module Spotify
  # A list of Spotify featured playlists shown on the 'Browse' tab.
  class GetFeaturedPlaylistsTool < Base
    description "Get a list of Spotify featured playlists"

    arguments do
      optional(:locale).filled(:string).description("The desired language and country, e.g. es_MX for Spanish (Mexico); defaults to American English")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("The maximum number of items to return (default 20, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("The index of the first item to return (default 0)")
    end

    def call(locale: nil, limit: nil, offset: nil)
      params = {}
      params[:locale] = locale if locale
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("browse/featured-playlists", params: params)
    end
  end
end
