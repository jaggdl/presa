# frozen_string_literal: true

module Strava
  # Fetches a piece of equipment (a bike or a pair of shoes) by its identifier.
  class GetGearTool < Base
    description "Fetch a single piece of equipment (gear) by ID"

    arguments do
      required(:id).filled(:string).description("The identifier of the equipment (e.g. a gear_id like b123456)")
    end

    def call(id:)
      strava_get("gear/#{id}")
    end
  end
end
