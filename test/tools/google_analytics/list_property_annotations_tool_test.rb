# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsListPropertyAnnotationsToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "list_property_annotations"
  end

  test "lists property annotations via the alpha admin endpoint" do
    tool = expose_google_analytics_tool("list_property_annotations") do |stub|
      stub.get("/v1alpha/properties/1234567/reportingDataAnnotations") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_analytics_json_response({ "reportingDataAnnotations" => [ { "name" => "annotation-1" } ] })
      end
    end

    result = tool.call(property_id: "1234567")
    assert_equal "annotation-1", result["reportingDataAnnotations"].first["name"]
  end
end
