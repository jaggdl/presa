# frozen_string_literal: true

module Tools
  module Jellyfin
    # Lists the episodes of a series (optionally a specific season) on the server.
    class GetEpisodes < Base
      description "List the episodes of a series (optionally a specific season) on the Jellyfin server"
      kind "get_episodes"

      arguments do
        required(:series_id).filled(:string).description("Id of the series to list episodes for")
        optional(:season_id).filled(:string).description("Id of the season to restrict results to")
        optional(:user_id).filled(:string).description("User id to scope results to")
        optional(:limit).filled(:integer, gt?: 0).description("Maximum number of episodes to return")
        optional(:fields).filled(:string).description("Comma-separated fields to include, e.g. Overview,DateCreated")
      end

      def call(series_id:, season_id: nil, user_id: nil, limit: nil, fields: nil)
        user_id = resolve_user_id(user_id)
        params = { userId: user_id }
        params[:seasonId] = season_id if season_id.present?
        params[:limit] = limit if limit.present?
        params[:fields] = fields if fields.present?

        service.get(media_url("/Shows/#{series_id}/Episodes", params))
      end
    end
  end
end
