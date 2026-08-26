# frozen_string_literal: true

module Jellyfin
  # Get the seasons for a series on the Jellyfin server.
  class GetSeasonsTool < Base
    description "Get the seasons of a series on the Jellyfin server"
    kind "get_seasons"

    arguments do
      required(:series_id).filled(:string).description("The ID of the series to get seasons for")
      optional(:user_id).filled(:string).description("The user ID to scope the request to")
      optional(:fields).filled(:string).description("Comma-separated fields to include in the response")
    end

    def call(series_id:, user_id: nil, fields: nil)
      user_id = resolve_user_id(user_id)
      params = { userId: user_id }
      params[:fields] = fields if fields.present?

      service.get(media_url("/Shows/#{series_id}/Seasons", params))
    end
  end
end
