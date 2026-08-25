require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "belongs to a user" do
    assert_equal users(:one), services(:github_prod).user
  end

  test "resolves a kind from the subclass" do
    assert_equal "github", services(:github_prod).kind
    assert_equal "github", Services::Github.kind
  end

  test "applies config defaults" do
    service = Services::Github.create!(user: users(:one), name: "Default", config: { api_token: "x" })

    assert_equal "https://api.github.com", service.config[:base_url]
  end

  test "requires required config fields" do
    service = Services::Github.new(user: users(:one), name: "Bad", config: { base_url: "https://x" })

    assert_not service.valid?
    assert_includes service.errors[:config], "api_token is required"
  end

  test "symbolizes config keys" do
    assert_equal "ghp_secret_token", services(:github_prod).config[:api_token]
    assert_equal "ghp_secret_token", services(:github_prod).config["api_token"]
  end

  test "encrypts config at rest" do
    service = Services::Github.create!(user: users(:one), name: "Encrypted", config: { api_token: "top_secret", base_url: "https://api.github.com" })

    raw = Service.connection.execute("SELECT config FROM services WHERE id = #{service.id}").first["config"]

    assert_not_includes raw, "top_secret"
  end

  test "enforces unique name per user and type" do
    service = Services::Github.new(user: users(:one), name: "Prod", config: { api_token: "x" })

    assert_not service.valid?
    assert_includes service.errors[:name], "has already been taken"
  end
end
