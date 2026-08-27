require "test_helper"

class Services::ParallelSearchTest < ActiveSupport::TestCase
  test "is a registered preset kind exposing only the api_key field" do
    assert_equal "parallel_search", Services::Parallel.kind
    assert_includes Service.kinds, "parallel_search"
    assert_equal [ "api_key" ], Services::Parallel.config_fields.keys.map(&:to_s)
  end

  test "uses the preset url" do
    assert_equal "https://search.parallel.ai/mcp", Services::Parallel.new.base_url
  end

  test "builds authorization header from the api_key config" do
    service = Services::Parallel.new(name: "Parallel Search")
    service.config = { api_key: "psk_123" }

    assert_equal({ "Authorization" => "Bearer psk_123" }, service.extra_headers)
  end

  test "requires an api_key" do
    service = Services::Parallel.new(name: "Parallel Search")
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("api_key") }
  end
end