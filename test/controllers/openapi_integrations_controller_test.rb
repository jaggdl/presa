# frozen_string_literal: true

require "test_helper"

class OpenapiIntegrationsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  def setup
    sign_in_as users(:one)
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

  test "parse turns a raw YAML spec into the step-2 configure panel" do
    post openapi_parse_path, params: { source: "raw", spec: @spec }, as: :turbo_stream

    assert_response :success
    assert_match /openapi-wizard/, response.body
    assert_match /Widget API/, response.body
    assert_match /4 operations/, response.body
  end

  test "parse rejects Swagger 2.0 with an inline error" do
    post openapi_parse_path, params: { source: "raw", spec: JSON.generate(swagger: "2.0", paths: {}) }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match /only OpenAPI 3\.x/i, response.body
  end

  test "parse accepts a URL source" do
    with_fetcher(@spec) do
      post openapi_parse_path, params: { source: "url", spec: "https://api.example.com/spec.yaml" }, as: :turbo_stream
    end

    assert_response :success
    assert_match /Widget API/, response.body
  end

  test "create_kind builds and saves the kind with chosen namespace" do
    definition = parse_definition
    token = store_draft(definition)

    assert_difference -> { OpenapiKind.count } do
      post openapi_create_kind_path, params: {
        draft_token: token,
        integration: {
          name: "My Widgets",
          namespace: "widgets",
          description: "Custom",
          base_url: "https://custom.example.com/v2"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    kind = OpenapiKind.last
    assert_equal "My Widgets", kind.title
    assert_equal "widgets", kind.namespace
    assert_equal "Custom", kind.description
    assert_equal "https://custom.example.com/v2", kind.base_url
    assert_equal 4, kind.operation_count
    assert_equal @team, kind.team
  end

  test "create_kind without a namespace falls back to the spec slug" do
    definition = parse_definition
    token = store_draft(definition)

    post openapi_create_kind_path, params: {
      draft_token: token,
      integration: { name: "Widgets" }
    }, as: :turbo_stream

    assert_response :success
    assert_equal "widget_api", OpenapiKind.last.namespace
  end

  test "create_kind with an expired/unknown draft shows the form again" do
    assert_no_difference -> { OpenapiKind.count } do
      post openapi_create_kind_path, params: {
        draft_token: "nope",
        integration: { name: "Widgets" }
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_match /expired/i, response.body
  end

  test "create_kind with a duplicate namespace fails validation inline" do
    OpenapiKind.create!(
      team: @team, title: "Existing", namespace: "widgets",
      definition: parse_definition.merge("namespace_slug" => "widgets")
    )

    definition = parse_definition.merge("namespace_slug" => "widgets")
    token = store_draft(definition)

    assert_no_difference -> { OpenapiKind.count } do
      post openapi_create_kind_path, params: {
        draft_token: token,
        integration: { name: "Widgets" }
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_match /already been taken/i, response.body
  end

  private

  def parse_definition
    raw, root = Openapi::Parser.parse(source: "raw", input: @spec)
    Openapi::Parser.validate!(raw)
    Openapi::Generator.generate(root)
  end

  def store_draft(definition)
    token = SecureRandom.hex(8)
    Rails.cache.write("openapi_draft:#{token}", definition, expires_in: 10.minutes)
    token
  end
end
