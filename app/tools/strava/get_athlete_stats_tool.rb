# frozen_string_literal: true

module Tools
  module Strava
    # Gets the authenticated athlete's activity and achievement stats (ytd
    # and all-time totals).
    class GetAthleteStatsTool < Base
      description "Get activity statistics for the authenticated athlete (year-to-date and all-time totals)"
      kind "get_athlete_stats"

      arguments do
        optional(:athlete_id).filled(:integer).description("Athlete ID to get stats for (defaults to the authenticated athlete)")
      end

      def call(athlete_id: nil)
        id = athlete_id
        if id.nil?
          athlete = service.get("/athlete")
          return athlete unless athlete.is_a?(Hash)

          id = athlete["id"]
        end

        service.get("/athletes/#{id}/stats")
      end
    end
  end
end