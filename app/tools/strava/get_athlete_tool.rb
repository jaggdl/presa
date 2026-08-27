# frozen_string_literal: true

module Tools
  module Strava
    # Gets the authenticated athlete's profile.
    class GetAthleteTool < Base
      description "Get the authenticated Strava athlete's profile"
      kind "get_athlete"

      arguments do
        optional(:fields).filled(:string).description("Comma-separated subset of fields to return (id, firstname, lastname, city, country, weight, etc.)")
      end

      def call(fields: nil)
        result = service.get("/athlete")
        return result if fields.nil? || !result.is_a?(Hash)

        requested = fields.split(",").map(&:strip)
        result.slice(*requested)
      end
    end
  end
end