# frozen_string_literal: true

require "test_helper"

class NotionGetPageToolTest < ActiveSupport::TestCase
  include NotionToolTestHelper

  ID = "abcdef1234567890abcdef1234567890"

  test "is exposed for notion services" do
    kinds = ApplicationTool.expose_for(services(:notion)).map(&:kind)
    assert_includes kinds, "get_page"
  end

  test "retrieves a page with a Notion-Version pin" do
    tool = expose_notion_tool("get_page") do |stub|
      stub.get("/v1/pages/#{ID}") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        assert_equal "2022-06-28", env.request_headers["Notion-Version"]
        notion_json_response({ id: ID, properties: { "Name" => { "title" => [] } } })
      end
    end

    result = tool.call(page_id: ID)
    assert_equal ID, result["id"]
  end

  test "normalizes a dashed UUID or a pasted URL to the bare hex id" do
    dashed_id = "#{ID[0, 8]}-#{ID[8, 4]}-#{ID[12, 4]}-#{ID[16, 4]}-#{ID[20, 12]}"

    dashed = expose_notion_tool("get_page") do |stub|
      stub.get("/v1/pages/#{ID}") { notion_json_response({ id: "ok" }) }
    end
    assert_equal({ "id" => "ok" }, dashed.call(page_id: dashed_id))

    from_url = expose_notion_tool("get_page") do |stub|
      stub.get("/v1/pages/#{ID}") { notion_json_response({ id: "ok" }) }
    end
    assert_equal({ "id" => "ok" }, from_url.call(page_id: "https://www.notion.so/My-Page-#{ID}"))
  end

  test "rejects an invalid page id" do
    tool = expose_notion_tool("get_page") do |stub|
      stub.get("/v1/pages/xyz") { notion_json_response({}) }
    end

    assert_raises(ArgumentError) { tool.call(page_id: "xyz") }
  end
end
