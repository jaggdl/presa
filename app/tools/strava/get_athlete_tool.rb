# frozen_string_literal: true

module Strava
  # Returns the authenticated athlete's public profile (name, city, country,
  # profile picture, units of measure preference, ...).
  class GetAthleteTool < Base
    description "Get the connected athlete's public profile"
    kind "get_athlete"

    def call
      strava_get("/api/v3/athlete")
    end
  end
end
