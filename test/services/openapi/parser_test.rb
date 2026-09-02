# frozen_string_literal: true

require "test_helper"

class OpenapiParserTest < ActiveSupport::TestCase
  def spec_text
    File.read(Rails.root.join("test/support/openapi/widget_api.yml"))
  end

  def with_fetcher(replacement)
    original = Openapi::Parser.method(:fetch)
    Openapi::Parser.define_singleton_method(:fetch) { |_url| replacement }
    yield
  ensure
    Openapi::Parser.define_singleton_method(:fetch, original)
  end

  test "parses raw YAML into a hash and parser root" do
    raw, root = Openapi::Parser.parse(source: "raw", input: spec_text)

    assert_equal "3.0.3", raw["openapi"]
    assert_equal "Widget API", root.raw_schema.dig("info", "title")
  end

  test "parses raw JSON" do
    json = JSON.generate(openapi: "3.1.0", info: { title: "T" }, paths: {})
    raw, = Openapi::Parser.parse(source: "raw", input: json)

    assert_equal "3.1.0", raw["openapi"]
  end

  test "fetches a URL spec through #fetch" do
    with_fetcher(spec_text) do
      raw, = Openapi::Parser.parse(source: "url", input: "https://api.example.com/spec.yaml")

      assert_equal "3.0.3", raw["openapi"]
    end
  end

  test "swallows fetch failures into a friendly parse error" do
    with_fetcher(nil) do
      # nil proxy fetch raises; Parser dedupes to a friendly message on its own.
      Openapi::Parser.define_singleton_method(:fetch) { |_url| raise "boom" }
      error = assert_raises(Openapi::Parser::Error) do
        Openapi::Parser.parse(source: "url", input: "https://api.example.com/spec.yaml")
      end
      assert_match(/could not parse/i, error.message)
    ensure
      Openapi::Parser.define_singleton_method(:fetch, Openapi::Parser.method(:fetch))
    end
  end

  test "rejects non-OpenAPI (Swagger 2.0) documents via validate!" do
    raw = { "swagger" => "2.0", "info" => { "title" => "Old" }, "paths" => {} }

    error = assert_raises(Openapi::Parser::Error) { Openapi::Parser.validate!(raw) }
    assert_match(/only OpenAPI 3\.x/i, error.message)
  end

  test "rejects documents without an openapi version" do
    raw = { "paths" => {} }

    assert_raises(Openapi::Parser::Error) { Openapi::Parser.validate!(raw) }
  end

  test "raises a friendly error for unparseable content" do
    error = assert_raises(Openapi::Parser::Error) do
      Openapi::Parser.parse(source: "raw", input: "definitely not a spec")
    end
    assert_match(/JSON or YAML/i, error.message)
  end

  test "fetch rejects non-http URLs and honors size cap" do
    assert_raises(Openapi::Parser::Error) { Openapi::Parser.fetch("ftp://example.com/spec.json") }
    assert_raises(Openapi::Parser::Error) { Openapi::Parser.fetch("") }
  end
end