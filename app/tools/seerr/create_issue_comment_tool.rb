# frozen_string_literal: true

module Seerr
  # Adds a comment to an issue.
  class CreateIssueCommentTool < Base
    description "Create a comment on a Seerr issue"
    kind :create_issue_comment

    arguments do
      required(:issueId).filled(:integer).description("ID of the issue to comment on")
      required(:message).filled(:string).description("Comment message")
    end

    def call(issueId:, message:)
      service.post("/issue/#{issueId}/comment", body: { message: message }.compact)
    end
  end
end