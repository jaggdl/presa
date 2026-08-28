# frozen_string_literal: true

module Strava
  # Fetches the comments for a single activity, optionally paginated.
  class GetActivityCommentsTool < Base
    description "Fetch a single activity's comments, optionally paginated"

    arguments do
      required(:id).filled(:integer).description("The ID of the activity, as returned by get_activities")
      optional(:page_size).filled(:integer, gt?: 0).description("Number of comments per page. Defaults to 30.")
      optional(:after_cursor).filled(:string).description("Cursor of the last item in the previous page of results")
    end

    def call(id:, page_size: nil, after_cursor: nil)
      params = {}
      params[:page_size] = page_size if page_size
      params[:after_cursor] = after_cursor if after_cursor
      strava_get("activities/#{id}/comments", params: params)
    end
  end
end
