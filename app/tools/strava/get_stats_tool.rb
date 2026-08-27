# frozen_string_literal: true

module Strava
  # Returns the authenticated athlete's aggregated sport stats (recent/ytd/all
  # totals for runs, rides, swims).
  class GetStatsTool < Base
    description "Get the authenticated athlete's aggregated activity stats"
    kind "get_stats"

    def call
      athlete = strava_get("/api/v3/athlete")
      id = athlete["id"]
      raise "Could not determine athlete id for stats" if id.blank?

      strava_get("/api/v3/athletes/#{id}/stats")
    end
  end
end
