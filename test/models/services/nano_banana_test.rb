# frozen_string_literal: true

require "test_helper"

class Services::NanoBananaTest < ActiveSupport::TestCase
  test "is an offerable native service" do
    assert_equal "nano_banana", Services::NanoBanana.kind
    assert_includes Service.kinds, "nano_banana"
  end

  test "is categorized as media" do
    assert_equal "media", Services::NanoBanana.category
  end

  test "requires an api_key config" do
    service = Services::NanoBanana.new(team: teams(:one), name: "Nano Banana", config: {})
    assert_not service.valid?
    assert_includes service.errors["config"], "api_key is required"
  end

  test "is valid with an api_key" do
    assert services(:nano_banana).valid?
  end

  test "exposes the generate, edit and list_models tools" do
    kinds = ApplicationTool.expose_for(services(:nano_banana)).map(&:kind)
    assert_includes kinds, "generate_image"
    assert_includes kinds, "edit_image"
    assert_includes kinds, "list_models"
  end

  test "defaults to the flash model" do
    assert_equal "gemini-3.1-flash-image", Services::NanoBanana::DEFAULT_MODEL
  end

  test "list_models returns image model ids from the API" do
    service = services(:nano_banana)
    response = Object.new
    response.define_singleton_method(:success?) { true }
    response.define_singleton_method(:body) do
      JSON.generate(models: [
        { "name" => "models/gemini-3.1-flash-image" },
        { "name" => "models/gemini-3-pro-image" },
        { "name" => "models/gemini-2.0-flash" }
      ])
    end
    Faraday.singleton_class.send(:define_method, :get) { |_url, _params = nil, &_block| response }

    assert_equal %w[gemini-3.1-flash-image gemini-3-pro-image], service.list_models
  ensure
    Faraday.singleton_class.send(:undef_method, :get)
  end

  test "url uses the requested model" do
    service = services(:nano_banana)
    url = service.send(:auth_url, "KEY", "gemini-3-pro-image")
    assert_includes url, "models/gemini-3-pro-image:generateContent"
    assert_includes url, "key=KEY"
  end

  test "test_connection lists models without generating an image" do
    service = services(:nano_banana)
    response = Object.new
    response.define_singleton_method(:success?) { true }
    Faraday.singleton_class.send(:define_method, :get) { |*_args, &_block| response }

    assert service.test_connection
  ensure
    Faraday.singleton_class.send(:undef_method, :get)
  end

  test "test_connection raises on a non-success response" do
    service = services(:nano_banana)
    response = Object.new
    response.define_singleton_method(:success?) { false }
    response.define_singleton_method(:status) { 401 }
    response.define_singleton_method(:body) { { error: { message: "API key not valid" } }.to_json }
    Faraday.singleton_class.send(:define_method, :get) { |*_args, &_block| response }

    error = assert_raises(RuntimeError) { service.test_connection }
    assert_includes error.message, "401"
  ensure
    Faraday.singleton_class.send(:undef_method, :get)
  end
end
