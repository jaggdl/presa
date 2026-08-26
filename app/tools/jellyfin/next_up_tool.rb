# frozen_string_literal: true

module Tools
  module Jellyfin
    # Lists episodes that are queued up to play next in the user's library.
    class NextUp < Base
      description "List next-up episodes for shows the user is currently watching on the Jellyfin server"
      kind "next_up"

      arguments do
        optional(:user_id).filled(:string).description("User ID to scope the request to (defaults to the first server user)")
        optional(:series_id).filled(:string).description("Series ID to restrict next-up items to")
        optional(:limit).filled(:integer, gt?: 0).description("Maximum number of results to return")
      end

      def call(user_id: nil, series_id: nil, limit: nil)
        user_id = resolve_user_id(user_id)
        params = { userId: user_id }
        params[:seriesId] = series_id if series_id.present?
        params[:limit] = limit if limit.present?

        service.get(media_url("/Shows/NextUp", params))
      end
    end
  end
end
