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
end
