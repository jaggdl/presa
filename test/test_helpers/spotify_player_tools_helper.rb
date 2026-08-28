# frozen_string_literal: true

# Shared support for testing Spotify Player tools. Each tool test file in
# `test/tools/spotify_player/` includes this module to get a bound tool whose
# API calls go through a Faraday test adapter (no network) and whose OAuth
# token comes from a fake service.
module SpotifyPlayerToolTestHelper
  # Builds a bound tool for `kind` against the `spotify_player` fixture. The
  # fake service supplies a fixed OAuth token, and the tool's Faraday
  # connection is swapped for a test adapter. `stub_block` receives a Faraday
  # stubs object.
  def expose_spotify_player_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:authorized_token) { "test-access-token" }

    klass = ApplicationTool.expose_for(services(:spotify_player)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool.define_singleton_method(:conn) do
      Faraday.new("https://api.spotify.com/v1") do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter :test, &stub_block
      end
    end
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test
  # adapter. Player control commands return 204 No Content.
  def spotify_player_response(status: 204, headers: {})
    [ status, headers, "" ]
  end
end
