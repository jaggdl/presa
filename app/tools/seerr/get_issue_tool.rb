# frozen_string_literal: true

module Seerr
  # Returns a single issue by ID.
  class GetIssueTool < Base
    description "Get a single Seerr issue by ID"
    kind :get_issue

    arguments do
      required(:issueId).filled(:integer).description("ID of the issue to fetch")
    end

    def call(issueId:)
      seerr_get("/issue/#{issueId}")
    end
  end
end
