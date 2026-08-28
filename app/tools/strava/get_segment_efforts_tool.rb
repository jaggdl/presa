# frozen_string_literal: true

module Strava
  # Lists the efforts on a given segment by the authenticated athlete, optionally
  # filtered to a date range.
  class GetSegmentEffortsTool < Base
    description "List an athlete's efforts on a segment for a given segment and date range"

    arguments do
      required(:id).filled(:integer).description("The ID of the segment")
      optional(:start_date_local).filled(:string).description("ISO 8601 local start time to filter efforts (e.g. 2018-01-01T00:00:00Z)")
      optional(:end_date_local).filled(:string).description("ISO 8601 local end time to filter efforts")
      optional(:page).filled(:integer).description("Page number. Defaults to 1.")
      optional(:per_page).filled(:integer, gt?: 0).description("Number of items per page. Defaults to 30.")
    end

    def call(id:, start_date_local: nil, end_date_local: nil, page: nil, per_page: nil)
      params = {}
      params[:start_date_local] = start_date_local if start_date_local
      params[:end_date_local] = end_date_local if end_date_local
      params[:page] = page if page
      params[:per_page] = per_page if per_page
      strava_get("segments/#{id}/all_efforts", params: params)
    end
  end
end
