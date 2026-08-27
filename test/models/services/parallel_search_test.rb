require "test_helper"

class Services::ParallelSearchTest < ActiveSupport::TestCase
  test "is a registered preset kind that requires no config fields" do
    assert_equal "parallel_search", Services::Parallel.kind
    assert_includes Service.kinds, "parallel_search"
    assert_empty Services::Parallel.config_fields
  end

  test "is categorized as knowledge" do
    assert_equal "knowledge", Services::Parallel.category
  end

  test "uses the preset url" do
    assert_equal "https://search.parallel.ai/mcp", Services::Parallel.new.base_url
  end

  test "sends no auth headers (public endpoint)" do
    assert_empty Services::Parallel.new.extra_headers
  end

  test "does not require any config to be valid" do
    service = Services::Parallel.new(name: "Parallel Search", user: users(:one))
    assert service.valid?
  end
end
