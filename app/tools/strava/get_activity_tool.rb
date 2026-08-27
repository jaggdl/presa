# frozen_string_literal: true

module Strava
  # Fetches one activity by ID, including detailed training/laps streams info
  # available to the authenticated athlete.
  class GetActivityTool < Base
    description "Fetch a single activity's detailed data by ID"
    kind "get_activity"

    arguments do
      required(:id).filled(:integer).description("The ID of the activity, as returned by get_activities")
    end

    def call(id:)
      strava_get("/api/v3/activities/#{id}")
    end
  end
end
