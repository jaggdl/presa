# frozen_string_literal: true

require "test_helper"

class NotionQueryDatabaseToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  ID = "abcdef1234567890abcdef1234567890"

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "query_database"
  end

  test "queries a database with filter and sorts" do
    tool = expose_notion_tool("query_database") do |stub|
      stub.post("/v1/databases/#{ID}/query") do |env|
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        body = JSON.parse(env.request_body)
        assert_equal({ "property" => "Status", "select" => { "equals" => "Done" } }, body["filter"])
        assert_equal(
          [ { "property" => "Due", "direction" => "ascending" } ],
          body["sorts"]
        )
        notion_json_response({ object: "list", results: [ { id: "row-1" } ] })
      end
    end

    filter = { property: "Status", select: { equals: "Done" } }
    sorts = [ { "property" => "Due", "direction" => "ascending" } ]
    result = tool.call(database_id: ID, filter: filter, sorts: sorts)
    assert_equal [ { "id" => "row-1" } ], result["results"]
  end

  test "passes pagination params" do
    tool = expose_notion_tool("query_database") do |stub|
      stub.post("/v1/databases/#{ID}/query") do |env|
        body = JSON.parse(env.request_body)
        assert_equal "cursor-1", body["start_cursor"]
        assert_equal 50, body["page_size"]
        notion_json_response({ object: "list", results: [] })
      end
    end

    tool.call(database_id: ID, cursor: "cursor-1", page_size: 50)
  end
end
