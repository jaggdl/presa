# frozen_string_literal: true

module Strava
  # Lists the clubs the authenticated athlete belongs to.
  class GetAthleteClubsTool < Base
    description "List the authenticated athlete's clubs"

    arguments do
      optional(:page).filled(:integer).description("Page number. Defaults to 1.")
      optional(:per_page).filled(:integer, gt?: 0).description("Number of items per page. Defaults to 30.")
    end

    def call(page: nil, per_page: nil)
      params = {}
      params[:page] = page if page
      params[:per_page] = per_page if per_page
      strava_get("athlete/clubs", params: params)
    end
  end
end
