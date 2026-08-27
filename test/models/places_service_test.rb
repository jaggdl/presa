# frozen_string_literal: true

require "test_helper"

class PlacesServiceTest < ActiveSupport::TestCase
  Request = Struct.new(:headers, :body) do
    def initialize(...)
      super
      self.headers ||= {}
    end
  end

  test "is an offerable Places kind with an api_key config" do
    assert_equal "places", Services::Places.kind
    assert_includes Service.kinds, "places"
    assert_equal [ "api_key" ], Services::Places.config_fields.keys.map(&:to_s)
    assert Services::Places.config_fields[:api_key][:secret]
  end

  test "is categorized as knowledge with the google icon" do
    assert_equal "knowledge", Services::Places.category
    assert_equal "places.png", Services::Places.icon
  end

  test "requires an api_key" do
    service = Services::Places.new(name: "Places")
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("api_key") }
  end

  test "is valid with an api_key" do
    assert services(:places).valid?
  end

  test "test_connection posts a minimal id-only search and returns true on 2xx" do
    request = nil
    Faraday.singleton_class.send(:define_method, :post) do |*_args, &block|
      req = Request.new
      block.call(req)
      request = req
      response = Object.new
      response.define_singleton_method(:success?) { true }
      response
    end

    service = Services::Places.new(user: users(:one), name: "Test", config: { api_key: "abc" })
    assert_equal true, service.test_connection

    body = JSON.parse(request.body)
    assert_equal "test", body["textQuery"]
    assert_equal 1, body["pageSize"]
    assert_equal "places.id", request.headers["X-Goog-FieldMask"]
    assert_equal "abc", request.headers["X-Goog-Api-Key"]
  ensure
    Faraday.singleton_class.send(:undef_method, :post)
  end

  test "test_connection raises on a non-2xx response" do
    Faraday.singleton_class.send(:define_method, :post) do |*_args, &_block|
      response = Object.new
      response.define_singleton_method(:success?) { false }
      response.define_singleton_method(:status) { 403 }
      response.define_singleton_method(:body) { '{"error":{"message":"forbidden"}}' }
      response
    end

    service = Services::Places.new(user: users(:one), name: "Test", config: { api_key: "abc" })
    error = assert_raises(RuntimeError) { service.test_connection }
    assert_match(/403/, error.message)
  ensure
    Faraday.singleton_class.send(:undef_method, :post)
  end
end
