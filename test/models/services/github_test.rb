require "test_helper"

class Services::GithubTest < ActiveSupport::TestCase
  test "is a registered preset kind exposing only the api_token field" do
    assert_equal "github", Services::Github.kind
    assert_includes Service.kinds, "github"
    assert_equal [ "api_token" ], Services::Github.config_fields.keys.map(&:to_s)
  end

  test "uses the preset url" do
    assert_equal "https://api.githubcopilot.com/mcp/", Services::Github.new.base_url
  end

  test "builds authorization header from the api_token config" do
    service = Services::Github.new(name: "GitHub")
    service.config = { api_token: "ghp_123" }

    assert_equal({ "Authorization" => "Bearer ghp_123" }, service.extra_headers)
  end

  test "requires an api_token" do
    service = Services::Github.new(name: "GitHub")
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("api_token") }
  end
end
