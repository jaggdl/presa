# frozen_string_literal: true

module Tools
  module Jellyfin
    # Lists items in a library folder (optionally filtered by item type) on the server.
    class ListLibraryItems < Base
      description "List items in a library folder on the Jellyfin server"
      kind "list_library_items"

      arguments do
        optional(:library_id).filled(:string).description("Id of the library folder to list items from")
        optional(:item_types).filled(:string).description("Comma-separated item types to include, e.g. Movie,Series")
        optional(:limit).filled(:integer, gt?: 0).description("Maximum number of items to return")
        optional(:user_id).filled(:string).description("User id to scope results to")
      end

      def call(library_id: nil, item_types: nil, limit: nil, user_id: nil)
        user_id = resolve_user_id(user_id)
        params = { userId: user_id, recursive: "true" }
        params[:parentId] = library_id if library_id.present?
        params[:includeItemTypes] = item_types if item_types.present?
        params[:limit] = limit if limit.present?

        service.get(media_url("/Users/#{user_id}/Items", params))
      end
    end
  end
end
