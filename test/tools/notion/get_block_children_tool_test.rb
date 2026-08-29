# frozen_string_literal: true

require "test_helper"

class NotionGetBlockChildrenToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  ID = "abcdef1234567890abcdef1234567890"

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "get_block_children"
  end

  test "lists child blocks with pagination params" do
    tool = expose_notion_tool("get_block_children") do |stub|
      stub.get("/v1/blocks/#{ID}/children") do |env|
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        assert_equal "cursor-1", env.params["start_cursor"]
        assert_equal "30", env.params["page_size"]
        notion_json_response({ object: "list", results: [ { type: "paragraph" } ] })
      end
    end

    result = tool.call(block_id: ID, cursor: "cursor-1", page_size: 30)
    assert_equal [ { "type" => "paragraph" } ], result["results"]
  end
end
