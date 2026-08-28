# frozen_string_literal: true

module Spotify
  # A list of new album releases featured in Spotify's Browse tab.
  class GetNewReleasesTool < Base
    description "Get a list of new album releases featured in Spotify"

    arguments do
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("The maximum number of items to return (default 20, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("The index of the first item to return (default 0)")
    end

    def call(limit: nil, offset: nil)
      params = {}
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("browse/new-releases", params: params)
    end
  end
end
