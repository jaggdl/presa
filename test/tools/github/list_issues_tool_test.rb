# frozen_string_literal: true

require "test_helper"

class GithubListIssuesToolTest < ActiveSupport::TestCase
  include GithubToolTestHelper

  test "is exposed for github services" do
    kinds = ApplicationTool.expose_for(services(:github_prod)).map(&:kind)
    assert_includes kinds, "list_issues"
  end

  test "lists issues for a repository" do
    tool, fake = expose_github_tool("list_issues")
    tool.call(repo: "owner/repo")

    assert_equal "/repos/owner/repo/issues", fake.last_path
  end
end
