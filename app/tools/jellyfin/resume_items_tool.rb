# frozen_string_literal: true

module Jellyfin
  # Lists partially-watched items the user can resume on the Jellyfin server.
  class ResumeItemsTool < Base
    description "List partially-watched items the user can resume on the Jellyfin server"

    arguments do
      optional(:limit).filled(:integer, gt?: 0).description("Maximum number of results to return")
      optional(:user_id).filled(:string).description("User ID to scope the request to (defaults to the first server user)")
    end

    def call(limit: nil, user_id: nil)
      user_id = resolve_user_id(user_id)
      params = { userId: user_id }
      params[:limit] = limit if limit.present?

      service.get(media_url("/Users/#{user_id}/Items/Resume", params))
    end
  end
end
