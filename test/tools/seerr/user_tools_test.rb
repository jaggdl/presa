# frozen_string_literal: true

require "test_helper"

class SeerrUserToolsTest < ActiveSupport::TestCase
  # Records the path passed to `get` so we can assert the API endpoint without
  # hitting the network. Returns a canned JSON response.
  class FakeService
    attr_reader :paths

    def initialize
      @paths = []
    end

    def get(path)
      @paths << path
      { "id" => 1, "displayName" => "Jane" }
    end

    def last_path
      @paths.last
    end
  end

  def expose_seerr_tool(kind)
    fake = FakeService.new
    klass = ApplicationTool.expose_for(services(:seerr)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake)
    [ tool, fake ]
  end

  test "user tools are exposed for seerr services" do
    kinds = ApplicationTool.expose_for(services(:seerr)).map(&:kind)
    assert_includes kinds, "get_all_users"
    assert_includes kinds, "get_user"
    assert_includes kinds, "get_user_by_jellyfin_id"
  end

  test "get_all_users hits GET /user" do
    tool, fake = expose_seerr_tool("get_all_users")

    result = tool.call

    assert_equal "/user", fake.last_path
    assert_equal 1, result["id"]
  end

  test "get_user hits GET /user/:userId" do
    tool, fake = expose_seerr_tool("get_user")

    result = tool.call(userId: 42)

    assert_equal "/user/42", fake.last_path
    assert_equal 1, result["id"]
  end

  test "get_user_by_jellyfin_id hits GET /user/jellyfin/:jellyfinUserId" do
    tool, fake = expose_seerr_tool("get_user_by_jellyfin_id")

    tool.call(jellyfinUserId: "jf-user-abc")

    assert_equal "/user/jellyfin/jf-user-abc", fake.last_path
  end

  test "get_user_by_jellyfin_id URL-encodes the jellyfin user id" do
    tool, fake = expose_seerr_tool("get_user_by_jellyfin_id")

    tool.call(jellyfinUserId: "a b/c")

    assert_equal "/user/jellyfin/a%20b%2Fc", fake.last_path
  end
end
