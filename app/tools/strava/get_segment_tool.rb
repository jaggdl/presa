# frozen_string_literal: true

module Strava
  # Fetches a single segment by ID, including its grade, elevation, city and
  # other summary data.
  class GetSegmentTool < Base
    description "Get a single segment by ID"

    arguments do
      required(:id).filled(:integer).description("The ID of the segment")
    end

    def call(id:)
      strava_get("segments/#{id}")
    end
  end
end
