# frozen_string_literal: true

require "test_helper"

class OpenapiDiscoveryTest < ActiveSupport::TestCase
  def fixture
    File.read(Rails.root.join("test/support/openapi/discovery_api.json"))
  end

  test "detects a Google Discovery document, not an OpenAPI one" do
    assert Openapi::Discovery.discovery?(JSON.parse(fixture))
    refute Openapi::Discovery.discovery?({ "openapi" => "3.0.3", "paths" => {} })
    refute Openapi::Discovery.discovery?("nope")
  end

  test "converts discovery resources, methods, and schemas into OpenAPI" do
    doc = Openapi::Discovery.to_openapi(JSON.parse(fixture))

    assert_equal "3.0.3", doc["openapi"]
    assert_equal "Example Discovery API", doc.dig("info", "title")
    assert_equal [ { "url" => "https://example.googleapis.com" } ], doc["servers"]
    assert_equal [ { "oauth2" => [ "https://www.googleapis.com/auth/example" ] } ], doc["security"]

    scheme = doc.dig("components", "securitySchemes", "oauth2")
    assert_equal "oauth2", scheme["type"]
    flow = scheme.dig("flows", "authorizationCode")
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", flow["authorizationUrl"]
    assert_equal "https://oauth2.googleapis.com/token", flow["tokenUrl"]
    assert_equal [ "https://www.googleapis.com/auth/example" ], flow["scopes"].keys

    list = doc.dig("paths", "/v1/projects/{projectsId}/things", "get")
    assert_equal "example.projects.listThings", list["operationId"]
    assert_equal [ "projects" ], list["tags"]
    assert_equal %w[projectsId pageSize filter], list["parameters"].map { |p| p["name"] }
    assert_equal "path", list["parameters"].first["in"]
    assert_equal true, list["parameters"].first["required"]
    assert_equal "#/components/schemas/ListThingsResponse",
                 list.dig("responses", "200", "content", "application/json", "schema", "$ref")

    create = doc.dig("paths", "/v1/projects/{projectsId}/things", "post")
    assert_equal "example.projects.things.create", create["operationId"]
    assert_equal "#/components/schemas/Thing",
                 create.dig("requestBody", "content", "application/json", "schema", "$ref")

    thing = doc.dig("components", "schemas", "Thing")
    assert_equal "#/components/schemas/Thing", thing.dig("properties", "parent", "$ref")
    assert_equal "string", thing.dig("properties", "labels", "additionalProperties", "type")
  end

  test "parse converts a discovery document and the standard pipeline generates it" do
    raw, root = Openapi::Parser.parse(source: "raw", input: fixture)
    Openapi::Parser.validate!(raw)

    definition = Openapi::Generator.generate(root)
    ids = definition["operations"].map { |op| op["operation_id"] }

    assert_includes ids, "example.projects.listThings"
    assert_includes ids, "example.projects.things.create"
    assert_equal "https://example.googleapis.com", definition["base_url"]
    assert_equal "oauth", definition.dig("security", "oauth2", "kind")
  end

  test "a discovery document still passes through when it has no schemas" do
    raw, root = Openapi::Parser.parse(source: "raw", input: JSON.generate(
      "kind" => "discovery#restDescription", "version" => "v1", "title" => "Bare",
      "rootUrl" => "https://bare.example.com", "resources" => {}
    ))

    assert_equal "3.0.3", raw["openapi"]
    assert_equal 0, Openapi::Generator.generate(root)["operation_count"]
  end
end
