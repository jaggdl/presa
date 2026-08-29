# frozen_string_literal: true

require "test_helper"

class NotionSearchToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "search"
  end

  test "searches with the query and a Notion-Version pin" do
    tool = expose_notion_tool("search") do |stub|
      stub.post("/v1/search") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        assert_equal({ "query" => "roadmap" }, JSON.parse(env.request_body))
        notion_json_response({ object: "list", results: [ { id: "page-1" } ] })
      end
    end

    result = tool.call(query: "roadmap")
    assert_equal [ { "id" => "page-1" } ], result["results"]
  end

  test "scopes the filter to a single object type" do
    tool = expose_notion_tool("search") do |stub|
      stub.post("/v1/search") do |env|
        body = JSON.parse(env.request_body)
        assert_equal({ "value" => "database", "property" => "object" }, body["filter"])
        notion_json_response({ object: "list", results: [] })
      end
    end

    tool.call(object_type: "database")
  end

  test "sorts by last edit time in the requested direction" do
    tool = expose_notion_tool("search") do |stub|
      stub.post("/v1/search") do |env|
        body = JSON.parse(env.request_body)
        assert_equal({ "direction" => "ascending", "timestamp" => "last_edited_time" }, body["sort"])
        notion_json_response({ object: "list", results: [] })
      end
    end

    tool.call(sort_direction: "ascending")
  end

  test "rejects an unknown object type" do
    tool = expose_notion_tool("search") do |stub|
      stub.post("/v1/search") { notion_json_response({ object: "list", results: [] }) }
    end

    assert_raises(ArgumentError) { tool.call(object_type: "widget") }
  end
end
