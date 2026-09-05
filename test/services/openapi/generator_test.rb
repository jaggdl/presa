# frozen_string_literal: true

require "test_helper"

class OpenapiGeneratorTest < ActiveSupport::TestCase
  def definition
    read_and_generate
  end

  def read_and_generate
    raw, root = Openapi::Parser.parse(source: "raw", input: File.read(Rails.root.join("test/support/openapi/widget_api.yml")))
    Openapi::Generator.generate(root)
  end

  test "extracts title, version, and operation/tag counts" do
    d = definition

    assert_equal "Widget API", d["title"]
    assert_equal "2.1", d["version"]
    assert_equal 4, d["operation_count"]
    assert_equal [ "widgets", "ops" ], d["tags"]
  end

  test "derives a namespace slug from the title" do
    assert_equal "widget_api", definition["namespace_slug"]
  end

  test "resolves the absolute server into the base URL" do
    assert_equal "https://api.example.com/v2", definition["base_url"]
  end

  test "resolves relative servers against the spec's origin when a source URL is given" do
    raw, root = Openapi::Parser.parse(source: "raw", input: <<~YAML)
      openapi: 3.0.0
      info: { title: "Rel", version: "1" }
      servers: [ { url: "/api" } ]
      paths: {}
    YAML

    d = Openapi::Generator.generate(root, source_url: "https://rel.example.com/spec.json")
    assert_equal "https://rel.example.com/api", d["base_url"]
  end

  test "leaves base_url nil when no absolute server and no source URL" do
    raw, root = Openapi::Parser.parse(source: "raw", input: <<~YAML)
      openapi: 3.0.0
      info: { title: "Rel", version: "1" }
      servers: [ { url: "/api" } ]
      paths: {}
    YAML

    assert_nil Openapi::Generator.generate(root)["base_url"]
  end

  test "turns security schemes into credential slots" do
    security = definition["security"]

    assert_equal "apikey", security["ApiKeyAuth"]["kind"]
    assert_equal "X-API-Key", security["ApiKeyAuth"]["param_name"]
    assert_equal "header", security["ApiKeyAuth"]["in"]

    assert_equal "bearer", security["bearerAuth"]["kind"]
    assert_equal "basic", security["basicAuth"]["kind"]
    assert_equal "cookie", security["cookieAuth"]["in"]
  end

  test "maps path, query, header, and body parameters into args schema" do
    op = definition["operations"].find { |o| o["operation_id"] == "createWidget" }
    props = op["args_schema"]["properties"]

    assert_equal %w[ meta name tags ], props.keys.sort
    assert_includes props["name"]["x-in"], "body"
    assert_equal "array", props["tags"]["type"]
    assert_includes op["args_schema"]["required"], "name"
  end

  test "inherits path-item parameters into operations that omit them" do
    op = definition["operations"].find { |o| o["operation_id"] == "deleteWidget" }
    props = op["args_schema"]["properties"]

    assert_equal "string", props["id"]["type"]
    assert_includes op["args_schema"]["required"], "id"
  end

  test "determines per-operation security (overrides global)" do
    op = definition["operations"].find { |o| o["operation_id"] == "getWidgetById" }
    assert_equal [ "bearerAuth", "ApiKeyAuth" ], op["security"]

    unauthed = definition["operations"].find { |o| o["operation_id"] == "healthCheck" }
    assert_empty unauthed["security"]
  end

  test "collects response fields for the identity picker" do
    op = definition["operations"].find { |o| o["operation_id"] == "createWidget" }

    assert_includes op["response_fields"], "items[0].id"
  end

  test "carries a parameter's single-value enum onto its args-schema property" do
    raw, root = Openapi::Parser.parse(source: "raw", input: <<~YAML)
      openapi: 3.0.0
      info: { title: "Pinned", version: "1" }
      paths:
        /ping:
          get:
            operationId: ping
            parameters:
              - name: Notion-Version
                in: header
                required: true
                schema:
                  type: string
                  enum: [ "2026-03-11" ]
            responses:
              "200": { description: OK }
    YAML

    d = Openapi::Generator.generate(root)
    op = d["operations"].first
    props = op["args_schema"]["properties"]

    assert_equal [ "2026-03-11" ], props["Notion-Version"]["enum"]
    assert_includes op["args_schema"]["required"], "Notion-Version"
  end
end
