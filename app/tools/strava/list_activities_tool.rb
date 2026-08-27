# frozen_string_literal: true

module Tools
  module Strava
    # Lists the authenticated athlete's recent activities.
    class ListActivitiesTool < Base
      description "List the authenticated athlete's recent activities from Strava"
      kind "list_activities"

      arguments do
        optional(:limit).filled(:integer, gt?: 0).description("Maximum number of activities to return (default 20, max 200)")
        optional(:before).filled(:integer).description("Unix timestamp; return activities started before this time")
        optional(:after).filled(:integer).description("Unix timestamp; return activities started after this time")
      end

      def call(limit: 20, before: nil, after: nil)
        params = { page: 1, per_page: [ limit, 200 ].min }
        params[:before] = before if before.present?
        params[:after] = after if after.present?

        service.get("/athlete/activities?#{URI.encode_www_form(params)}")
      end
    end
  end
end