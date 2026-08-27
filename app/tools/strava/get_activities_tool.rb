# frozen_string_literal: true

module Strava
  # Lists the authenticated athlete's activities, most recent first. Supports
  # optional `before`/`after` epoch timestamps and a page size.
  class GetActivitiesTool < Base
    description "List the authenticated athlete's activities (most recent first)"
    kind "get_activities"

    arguments do
      optional(:before).filled(:integer).description("An epoch timestamp to return activities started before this time")
      optional(:after).filled(:integer).description("An epoch timestamp to return activities started after this time")
      optional(:page).filled(:integer, gt?: 1).description("Page number of results (default 1)")
      optional(:per_page).filled(:integer, gt?: 0, lteq?: 200).description("Number of activities per page (default 30, max 200)")
    end

    def call(before: nil, after: nil, page: nil, per_page: nil)
      params = {}
      params[:before] = before if before
      params[:after] = after if after
      params[:page] = page if page
      params[:per_page] = per_page if per_page
      strava_get("athlete/activities", params: params)
    end
  end
end
