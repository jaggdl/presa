# frozen_string_literal: true

module Jellyfin
  # Lists items similar to a given item in the user's media library.
  class SimilarItemsTool < Base
    description "List items similar to a given Jellyfin item"

    arguments do
      required(:item_id).filled(:string).description("ID of the item to find similar items for")
      optional(:limit).filled(:integer).description("Maximum number of similar items to return")
      optional(:user_id).filled(:string).description("User ID to scope the request to")
    end

    def call(item_id:, limit: nil, user_id: nil)
      user_id = resolve_user_id(user_id)
      params = { userId: user_id }
      params[:limit] = limit if limit.present?

      service.get(media_url("/Items/#{item_id}/Similar", params))
    end
  end
end
