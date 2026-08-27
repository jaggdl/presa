# frozen_string_literal: true

module Tools
  module Strava
    # Gets a single activity by its Strava ID.
    class GetActivityTool < Base
      description "Get detailed information about a specific Strava activity by ID"
      kind "get_activity"

      arguments do
        required(:activity_id).filled(:integer).description("Strava activity ID to retrieve")
        optional(:include_all_efforts).filled(:bool).description("Include segment efforts (default false)")
      end

      def call(activity_id:, include_all_efforts: false)
        query = include_all_efforts ? "?include_all_efforts=true" : ""
        service.get("/activities/#{activity_id}#{query}")
      end
    end
  end
end