# frozen_string_literal: true

module Strava
  # Returns the athlete's heart rate and power zones.
  class GetAthleteZonesTool < Base
    description "Get the authenticated athlete's heart rate and power zones"

    def call
      strava_get("athlete/zones")
    end
  end
end
