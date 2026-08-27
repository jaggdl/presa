# frozen_string_literal: true

require "test_helper"

class StravaToolTestHelperTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "fake service records get paths" do
    fake = FakeStravaService.new
    fake.get("/athlete")
    assert_includes fake.paths, "/athlete"
  end

  test "fake service returns canned athlete" do
    fake = FakeStravaService.new
    fake.set_athlete_response({ "id" => 42, "firstname" => "Eddy" })
    result = fake.get("/athlete")
    assert_equal 42, result["id"]
    assert_equal "Eddy", result["firstname"]
  end

  test "fake service returns custom responses" do
    fake = FakeStravaService.new
    fake.set_response("/athlete/activities", [ { "id" => 1 } ])
    result = fake.get("/athlete/activities")
    assert_equal 1, result[0]["id"]
  end

  test "expose_strava_tool returns a bound tool" do
    tool, fake = expose_strava_tool("get_athlete")
    assert tool.respond_to?(:call)
    assert fake.is_a?(FakeStravaService)
  end
end