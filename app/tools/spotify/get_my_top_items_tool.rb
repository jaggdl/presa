# frozen_string_literal: true

module Spotify
  # The current user's top artists or tracks, based on calculated affinity.
  class GetMyTopItemsTool < Base
    description "Get the current user's top artists or tracks based on listening affinity"
    kind "get_my_top_items"

    arguments do
      required(:type).filled(:string, included_in?: %w[artists tracks]).description("The type of entity to return: artists or tracks")
      optional(:time_range).filled(:string, included_in?: %w[short_term medium_term long_term]).description("Time frame for the affinities: short_term (~4 weeks), medium_term (~6 months), long_term (~1 year). Default medium_term")
      optional(:limit).filled(:integer, gteq?: 0, lteq?: 50).description("Maximum number of items to return (default 20, min 1, max 50)")
      optional(:offset).filled(:integer, gteq?: 0).description("Index of the first item to return (default 0)")
    end

    def call(type:, time_range: nil, limit: nil, offset: nil)
      params = { type: type }
      params[:time_range] = time_range if time_range
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      spotify_get("me/top/#{params.delete(:type)}", params: params)
    end
  end
end
