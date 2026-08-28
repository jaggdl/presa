# frozen_string_literal: true

module Strava
  # Fetches the set of stream types for a specific activity for the
  # authenticated athlete. Optionally limits the stream types returned and
  # whether they are keyed by type.
  class GetActivityStreamsTool < Base
    description "Get the streams (time, distance, latlng, etc.) for an activity"

    arguments do
      required(:id).filled(:integer).description("The ID of the activity, as returned by get_activities")
      optional(:keys).filled(:string).description("Comma-separated list of stream types to return (e.g. distance,time,latlng)")
      optional(:keys_by_type).filled(:bool).description("Return streams by key (true) or in a flat array (false)")
    end

    def call(id:, keys: nil, keys_by_type: nil)
      params = {}
      params[:keys] = keys if keys
      params[:keys_by_type] = keys_by_type if !keys_by_type.nil?
      strava_get("activities/#{id}/streams", params: params)
    end
  end
end
