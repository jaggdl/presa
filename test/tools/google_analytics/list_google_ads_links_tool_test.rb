# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsListGoogleAdsLinksToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "list_google_ads_links"
  end

  test "lists google ads links for the property" do
    tool = expose_google_analytics_tool("list_google_ads_links") do |stub|
      stub.get("/v1beta/properties/1234567/googleAdsLinks") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_analytics_json_response({ "googleAdsLinks" => [ { "name" => "properties/1234567/googleAdsLinks/1" } ] })
      end
    end

    result = tool.call(property_id: "1234567")
    assert_equal 1, result["googleAdsLinks"].length
  end
end
