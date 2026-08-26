require "test_helper"

class Mcp::ClientTest < ActiveSupport::TestCase
  def build_client(&stub)
    conn = Faraday.new("https://example.com/mcp") { |f| f.adapter :test, &stub }
    ::Mcp::Client.new(url: "https://example.com/mcp", connection: conn)
  end

  def json_response(id, result = {})
    [ 200, { "content-type" => "application/json" }, JSON.generate({ jsonrpc: "2.0", id: id, result: result }) ]
  end

  test "initializes, notifies, then lists tools" do
    saw_ids = []
    client = build_client do |stub|
      stub.post(/.*/) do |env|
        saw_ids << env.body
        payload = JSON.parse(env.body)
        case payload["method"]
        when "initialize" then json_response(payload["id"], { capabilities: {} })
        when "notifications/initialized" then [ 200, {}, "" ]
        when "tools/list" then json_response(payload["id"], { "tools" => [ { "name" => "web_search" } ] })
        end
      end
    end

    tools = client.list_tools
    assert_equal [ "web_search" ], tools["tools"].map { |t| t["name"] }
    methods = saw_ids.map { |b| JSON.parse(b)["method"] }
    assert_equal [ "initialize", "notifications/initialized", "tools/list" ], methods
  end

  test "raises on a json-rpc error" do
    client = build_client do |stub|
      stub.post(/.*/) do |env|
        payload = JSON.parse(env.body)
        case payload["method"]
        when "initialize" then json_response(payload["id"], {})
        when "notifications/initialized" then [ 200, {}, "" ]
        when "tools/list"
          [ 200, { "content-type" => "application/json" },
            JSON.generate({ jsonrpc: "2.0", id: payload["id"], error: { "code" => -32601, "message" => "boom" } }) ]
        end
      end
    end
    assert_raises(::Mcp::Error) { client.list_tools }
  end
end
