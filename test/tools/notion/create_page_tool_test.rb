# frozen_string_literal: true

require "test_helper"

class NotionCreatePageToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "create_page"
  end

  test "creates a page under a database parent with string-keyed properties" do
    tool = expose_notion_tool("create_page") do |stub|
      stub.post("/v1/pages") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        body = JSON.parse(env.request_body)
        assert_equal({ "database_id" => "db1" }, body["parent"])
        assert_equal "Task", body.dig("properties", "Name", "title", 0, "text", "content")
        notion_json_response({ id: "page-9", object: "page" })
      end
    end

    parent = { database_id: "db1" }
    properties = { "Name" => { "title" => [ { "text" => { "content" => "Task" } } ] } }
    result = tool.call(parent: parent, properties: properties)
    assert_equal "page-9", result["id"]
  end

  test "passes the given child blocks through" do
    tool = expose_notion_tool("create_page") do |stub|
      stub.post("/v1/pages") do |env|
        body = JSON.parse(env.request_body)
        assert_equal "heading_2", body.dig("children", 0, "type")
        notion_json_response({ id: "page-9" })
      end
    end

    children = [ { "object" => "block", "type" => "heading_2", "heading_2" => { "rich_text" => [] } } ]
    tool.call(parent: { "page_id" => "p1" }, properties: { "title" => { "title" => [] } }, children: children)
  end
end
