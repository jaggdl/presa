# frozen_string_literal: true

module Strava
  # Lists the segments the authenticated athlete has starred.
  class GetStarredSegmentsTool < Base
    description "List the authenticated athlete's starred segments"

    arguments do
      optional(:page).filled(:integer).description("Page number. Defaults to 1.")
      optional(:per_page).filled(:integer, gt?: 0).description("Number of items per page. Defaults to 30.")
    end

    def call(page: nil, per_page: nil)
      params = {}
      params[:page] = page if page
      params[:per_page] = per_page if per_page
      strava_get("segments/starred", params: params)
    end
  end
end
