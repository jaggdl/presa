# frozen_string_literal: true

module Tools
  module Jellyfin
    # Gets details for a specific item in the user's media library.
    class GetItemDetails < Base
      description "Get detailed metadata for a specific Jellyfin item"
      kind "get_item_details"

      arguments do
        required(:item_id).filled(:string).description("ID of the item to fetch details for")
        optional(:user_id).filled(:string).description("User ID to scope the request to")
        optional(:fields).filled(:string).description("Comma-separated additional fields to include, e.g. Overview,Genres")
      end

      def call(item_id:, user_id: nil, fields: nil)
        user_id = resolve_user_id(user_id)
        params = {}
        params[:fields] = fields if fields.present?

        service.get(media_url("/Users/#{user_id}/Items/#{item_id}", params))
      end
    end
  end
end
