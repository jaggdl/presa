# frozen_string_literal: true

require "test_helper"

class RegistryOpenapiTest < ActiveSupport::TestCase
  setup do
    @team = teams(:one)
    @spec = File.read(Rails.root.join("test/support/openapi/widget_api.yml"))
  end

  def with_fetcher(replacement)
    original = Openapi::Parser.method(:fetch)
    Openapi::Parser.define_singleton_method(:fetch) { |_url| replacement }
    yield
  ensure
    Openapi::Parser.define_singleton_method(:fetch, original)
  end

  test "install persists the preset category on the kind" do
    with_fetcher(@spec) do
      kind = Registry::Openapi.install("figma", team: @team)
      assert kind.persisted?
    end

    kind = OpenapiKind.find_by(namespace: "figma")
    assert_equal "productivity", kind.category
  end

  test "a preset without a category defaults to general" do
    preset = Registry::Openapi::Preset.new("x", { "title" => "X" })
    assert_equal "general", preset.category
  end

  test "an installed kind's virtual service class reports the preset category, not General" do
    with_fetcher(@spec) do
      Registry::Openapi.install("sonarr", team: @team)
    end

    klass = Services::Openapi.virtual_class_for("sonarr")
    assert_equal "media", klass.new.category
  end

  test "a preset oauth_provider override is stored on the installed kind" do
    with_fetcher(@spec) do
      Registry::Openapi.install("youtube_analytics", team: @team)
    end

    kind = OpenapiKind.find_by(namespace: "youtube_analytics")
    assert_equal "google", kind.read_attribute(:oauth_provider)
  end

  test "a kind with the google override resolves the static Google provider for its virtual class" do
    definition = {
      "operations" => [], "operation_count" => 0, "tag_count" => 0,
      "security" => {
        "Oauth2c" => {
          "kind" => "oauth",
          "authorization_url" => "https://accounts.google.com/o/oauth2/auth",
          "token_url" => "https://accounts.google.com/o/oauth2/token",
          "scopes" => { "https://www.googleapis.com/auth/yt-analytics.readonly" => "View reports" }
        }
      }
    }
    OpenapiKind.create!(team: @team, title: "YouTube Analytics", namespace: "youtube_analytics",
                        oauth_provider: "google", category: "productivity", definition: definition)

    klass = Services::Openapi.virtual_class_for("youtube_analytics")
    assert_equal "google", klass.oauth_provider
    assert_equal "google", klass.new.oauth_provider_key
    assert_equal Oauth::Google, klass.provider_class
    assert_equal "https://www.googleapis.com/auth/yt-analytics.readonly", klass.oauth_scope
  end
end
