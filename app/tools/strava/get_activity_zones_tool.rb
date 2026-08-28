# frozen_string_literal: true

module Strava
  # Fetches the activity's power/aerobic zones for the authenticated athlete.
  class GetActivityZonesTool < Base
    description "Retrieve the heart rate and power zones for an activity"

    arguments do
      required(:id).filled(:integer).description("The ID of the activity, as returned by get_activities")
    end

    def call(id:)
      strava_get("activities/#{id}/zones")
    end
  end
end
