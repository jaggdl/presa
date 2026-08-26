# frozen_string_literal: true

require "test_helper"

class JellyfinGetEpisodesToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "get_episodes"
  end

  test "hits the series episodes endpoint with a user id" do
    tool, fake = expose_jellyfin_tool("get_episodes")
    tool.call(series_id: "series-1")

    path = fake.last_path
    assert_includes path, "/Shows/series-1/Episodes?"
    assert_includes path, "userId="
  end

  test "includes season, limit and fields when given" do
    tool, fake = expose_jellyfin_tool("get_episodes")
    tool.call(series_id: "series-1", season_id: "season-2", limit: 5, fields: "Overview,DateCreated")

    path = fake.last_path
    assert_includes path, "/Shows/series-1/Episodes?"
    assert_includes path, "seasonId=season-2"
    assert_includes path, "limit=5"
    assert_includes path, "fields=Overview%2CDateCreated"
  end
end
