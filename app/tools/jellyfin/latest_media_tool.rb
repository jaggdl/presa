# frozen_string_literal: true

module Tools
  module Jellyfin
    # Lists the latest items added to the user's media library.
    class LatestMedia < Base
      description "List the latest media items added to the Jellyfin server"
      kind "latest_media"

      arguments do
        optional(:limit).filled(:integer, gt?: 0).description("Maximum number of items to return")
        optional(:include_item_types).filled(:string).description("Comma-separated item types to restrict to, e.g. Movie,Series")
      end

      def call(limit: 10, include_item_types: nil)
        user_id = resolve_user_id(nil)
        params = { limit: limit, fields: "DateCreated,Genres,Overview" }
        if include_item_types.present?
          params[:includeItemTypes] = include_item_types
          params[:recursive] = "true"
        end

        service.get(media_url("/Users/#{user_id}/Items/Latest", params))
      end
    end
  end
end
