# frozen_string_literal: true

module Strava
  # Fetches the list of kudos (likes) for a single activity by ID.
  class GetActivityKudosTool < Base
    description "Fetch a single activity's kudos (likes) by ID"

    arguments do
      required(:id).filled(:integer).description("The ID of the activity, as returned by get_activities")
      optional(:page).filled(:integer).description("Page number. Defaults to 1.")
      optional(:per_page).filled(:integer, gt?: 0).description("Number of items per page. Defaults to 30.")
    end

    def call(id:, page: nil, per_page: nil)
      params = {}
      params[:page] = page if page
      params[:per_page] = per_page if per_page
      strava_get("activities/#{id}/kudos", params: params)
    end
  end
end
