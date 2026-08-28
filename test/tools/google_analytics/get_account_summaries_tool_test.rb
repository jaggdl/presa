# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsGetAccountSummariesToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "get_account_summaries"
  end

  test "fetches account summaries with an auth header" do
    tool = expose_google_analytics_tool("get_account_summaries") do |stub|
      stub.get("/v1beta/accountSummaries") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_analytics_json_response({ "accountSummaries" => [ { "account" => "accounts/123" } ] })
      end
    end

    result = tool.call
    assert_equal "accounts/123", result["accountSummaries"].first["account"]
  end
end
