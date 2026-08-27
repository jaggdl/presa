# frozen_string_literal: true

module Seerr
  # Returns the number of open/closed issues and issues of each type.
  class GetIssueCountsTool < Base
    description "Get Seerr issue counts by status and type"
    kind :get_issue_counts

    def call
      seerr_get("/issue/count")
    end
  end
end
