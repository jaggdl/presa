# frozen_string_literal: true

module Seerr
  # Updates an issue's status to open or resolved.
  class UpdateIssueStatusTool < Base
    description "Update a Seerr issue's status to open or resolved"
    kind :update_issue_status

    arguments do
      required(:issueId).filled(:integer).description("ID of the issue to update")
      required(:status).filled(:string).description("New status: 'open' or 'resolved'")
    end

    def call(issueId:, status:)
      service.post("/issue/#{issueId}/#{status}")
    end
  end
end
