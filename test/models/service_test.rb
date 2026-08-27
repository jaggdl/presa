require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "icon returns the declared brand image" do
    assert_equal "github.png", services(:github_prod).icon
    assert_equal "jellyfin.png", services(:jellyfin).icon
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
end
