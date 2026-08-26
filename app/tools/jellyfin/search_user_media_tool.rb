# frozen_string_literal: true

module Jellyfin
  # Searches the user's media library on the Jellyfin server.
  class SearchUserMediaTool < Base
    description "Search the user's media library on the Jellyfin server"
    kind "search_user_media"

    arguments do
      required(:query).filled(:string).description("Search term to match against media titles")
      optional(:limit).filled(:integer, gt?: 0).description("Maximum number of results to return")
      optional(:include_item_types).filled(:string).description("Comma-separated item types to restrict to, e.g. Movie,Series")
    end

    def call(query:, limit: 20, include_item_types: nil)
      user_id = resolve_user_id(nil)
      params = { searchTerm: query, recursive: "true", limit: limit }
      params[:includeItemTypes] = include_item_types if include_item_types.present?

      service.get(media_url("/Users/#{user_id}/Items", params))
    end
  end
end
