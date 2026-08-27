# frozen_string_literal: true

# Shared support for testing Strava tools. Provides a fake service that
# records requested paths and returns canned responses so tests never hit
# the Strava network.
module StravaToolTestHelper
  # Captures arguments passed to `get` and `post` so tests can assert the
  # endpoint and payload without any network access.
  class FakeStravaService
    attr_reader :last_path, :last_body, :paths

    def initialize
      @paths = []
      @athlete_response = nil
      @responses = {}
    end

    def set_athlete_response(data)
      @athlete_response = data
    end

    def set_response(path, data)
      @responses[path] = data
    end

    def get(path)
      @paths << path
      @last_path = path
      return @athlete_response if path == "/athlete"
      return @responses[path] if @responses.key?(path)

      nil
    end

    def post(path, body: nil, headers: {})
      @paths << path
      @last_path = path
      @last_body = body
      nil
    end
  end

  # Builds the bound tool class for `kind` against a fake service.
  # Returns `[tool, fake]`.
  def expose_strava_tool(kind)
    fake = FakeStravaService.new
    fake.set_athlete_response({ "id" => 12345678, "firstname" => "Test", "lastname" => "Athlete" })
    klass = ApplicationTool.expose_for(services(:strava)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake)
    [ tool, fake ]
  end
end