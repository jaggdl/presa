# frozen_string_literal: true

module Tools
  module Github
    # Lists issues for a repository using the GitHub service's config.
    class ListIssues < Base
      description "List issues for a repository"
      kind :list_issues

      arguments do
        required(:repo).filled(:string).description("Repository in owner/name format")
      end

      def call(repo:)
        service.get("/repos/#{repo}/issues")
      end
    end
  end
end
