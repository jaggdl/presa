# frozen_string_literal: true

module Seerr
  # Returns a single issue comment by ID.
  class GetIssueCommentTool < Base
    description "Get a single Seerr issue comment by ID"
    kind :get_issue_comment

    arguments do
      required(:commentId).filled(:integer).description("ID of the comment to fetch")
    end

    def call(commentId:)
      seerr_get("/issueComment/#{commentId}")
    end
  end
end