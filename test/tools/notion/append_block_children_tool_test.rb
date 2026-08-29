# frozen_string_literal: true

require "test_helper"

class NotionAppendBlockChildrenToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  ID = "abcdef1234567890abcdef1234567890"

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "append_block_children"
  end

  test "appends child blocks under a block" do
    tool = expose_notion_tool("append_block_children") do |stub|
      stub.patch("/v1/blocks/#{ID}/children") do |env|
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        body = JSON.parse(env.request_body)
        assert_equal "heading_2", body.dig("children", 0, "type")
        notion_json_response({ object: "list", results: [ { id: "block-1" } ] })
      end
    end

    children = [ { object: "block", type: "heading_2", heading_2: { rich_text: [] } } ]
    result = tool.call(block_id: ID, children: children)
    assert_equal [ { "id" => "block-1" } ], result["results"]
  end
end
