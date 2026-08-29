# frozen_string_literal: true

require "test_helper"

class NotionGetDatabaseToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  ID = "abcdef1234567890abcdef1234567890"

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "get_database"
  end

  test "retrieves a database by id, normalizing a pasted URL" do
    tool = expose_notion_tool("get_database") do |stub|
      stub.get("/v1/databases/#{ID}") do |env|
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        notion_json_response({ id: ID, title: [ { "plain_text" => "Tasks" } ] })
      end
    end

    result = tool.call(database_id: "https://www.notion.so/#{ID}")
    assert_equal ID, result["id"]
  end
end
