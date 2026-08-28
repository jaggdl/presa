# frozen_string_literal: true

module Strava
  # Fetches the split (lap) data for a single activity by ID.
  class GetActivityLapsTool < Base
    description "Fetch a single activity's laps (splits) by ID"

    arguments do
      required(:id).filled(:integer).description("The ID of the activity, as returned by get_activities")
    end

    def call(id:)
      strava_get("activities/#{id}/laps")
    end
  end
end
