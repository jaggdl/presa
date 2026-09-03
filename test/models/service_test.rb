require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "icon returns the declared brand image" do
    assert_equal "github.png", services(:github_prod).icon
    assert_equal "seerr.png", services(:seerr).icon
  end

  test "icon falls back to placeholder when the kind has not declared one" do
    klass = Class.new(Service)
    service = klass.new(name: "Generic")
    assert_equal "placeholder.png", service.icon
    assert_not service.invert_icon?
  end

  test "github icon is inverted for dark backgrounds" do
    assert services(:github_prod).invert_icon?
  end

  test "config values are stripped of surrounding whitespace" do
    service = services(:github_prod)
    service.config = { api_token: "  token  ", base_url: " https://api.github.com " }

    assert_equal "token", service.config[:api_token]
    assert_equal "https://api.github.com", service.config[:base_url]
  end

  test "each concrete service kind declares a markdown description" do
    Service.concrete_service_classes.each do |klass|
      next if klass.config_fields.blank?

      assert klass.description.present?, "#{klass.kind} should declare a description"
    end
  end

  test "test_connection? is true only for kinds with a real connectivity probe" do
    assert Services::Seerr.test_connection?, "seerr should support a connectivity probe"
    assert Services::Mcp.test_connection?, "mcp should support a connectivity probe"
    assert_not Services::WorkplaceAdmin.test_connection?, "workplace admin has no connectivity probe"
    assert_not Services::Gmail.test_connection?, "OAuth services use the exchange, not a probe"
  end

  test "destroy removes linked tool invocations" do
    service = services(:seerr)
    token = workspaces(:one).api_tokens.create!(name: "Test", token_digest: "digest")

    service.tool_invocations.create!(api_token: token, tool_name: "seerr_other", arguments: {})

    assert_difference -> { ToolInvocation.where(service_id: service.id).count }, -1 do
      service.destroy!
    end
  end
end
