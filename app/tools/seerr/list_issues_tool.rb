# frozen_string_literal: true

module Seerr
  # Lists all issues reported on the Seerr instance, optionally filtered.
  class ListIssuesTool < Base
    description "List issues reported on the Seerr instance"
    kind :list_issues

    arguments do
      optional(:take).filled(:integer).description("Number of issues to return (default 20)")
      optional(:skip).filled(:integer).description("Number of issues to skip for pagination")
      optional(:sort).filled(:string).description("Sort order: added, modified (default added)")
      optional(:filter).filled(:string).description("Filter by status: all, open, resolved (default open)")
      optional(:requestedBy).filled(:integer).description("Only return issues reported by the given user ID")
    end

    def call(take: nil, skip: nil, sort: nil, filter: nil, requestedBy: nil)
      seerr_get("/issue", take: take, skip: skip, sort: sort, filter: filter, requestedBy: requestedBy)
    end
  end
end