# frozen_string_literal: true

module Spotify
  # The current user's recently played tracks (does not include podcast
  # episodes). Supports cursor-based paging with `after`/`before` Unix
  # millisecond timestamps.
  class GetRecentlyPlayedTool < Base
    description "Get tracks from the current user's recently played tracks"

    arguments do
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of items to return (default 20, min 1, max 50)")
      optional(:after).filled(:integer, gteq?: 0).description("Unix timestamp in milliseconds; return items after (but not including) this cursor position")
      optional(:before).filled(:integer, gteq?: 0).description("Unix timestamp in milliseconds; return items before (but not including) this cursor position")
    end

    def call(limit: nil, after: nil, before: nil)
      params = {}
      params[:limit] = limit if limit
      params[:after] = after if after
      params[:before] = before if before
      spotify_get("me/player/recently-played", params: params)
    end
  end
end
