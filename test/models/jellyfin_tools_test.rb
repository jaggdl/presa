require "test_helper"

class JellyfinToolsTest < ActiveSupport::TestCase
  class FakeService
    attr_reader :captured_mean

    def initialize(&block)
      @get = block
    end

    def get(path)
      @get.call(path)
    end
  end

  def expose(kind, fake)
    klass = ApplicationTool.expose_for(services(:jellyfin)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake)
    tool
  end

  test "exposes search and latest tools" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "search_user_media"
    assert_includes kinds, "latest_media"
  end

  test "search_user_media hits the user items endpoint with the query" do
    captured = nil
    fake = FakeService.new { |path| captured = path }
    expose("search_user_media", fake).call(query: "star")

    assert_includes captured, "/Users/"
    assert_includes captured, "/Items?"
    assert_includes captured, "searchTerm=star"
    assert_includes captured, "limit=20"
  end

  test "search_user_media includes item type filter when given" do
    captured = nil
    fake = FakeService.new { |path| captured = path }
    expose("search_user_media", fake).call(query: "star", include_item_types: "Movie,Series")

    assert_includes captured, "includeItemTypes=Movie%2CSeries"
  end

  test "latest_media hits the latest endpoint" do
    captured = nil
    fake = FakeService.new { |path| captured = path }
    expose("latest_media", fake).call(limit: 5)

    assert_includes captured, "/Users/"
    assert_includes captured, "/Items/Latest?"
    assert_includes captured, "limit=5"
  end
end
