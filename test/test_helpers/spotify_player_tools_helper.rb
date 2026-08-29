# frozen_string_literal: true

# Shared support for testing Spotify Player tools. Each tool test file in
# `test/tools/spotify_player/` includes this module to get a bound tool whose
# API calls go through an `Oauth::Client` with a Faraday test adapter (no
# network) and whose OAuth token comes from a fake service. The helper lets
# the test stub responses per path and inspect the Authorization header that
# was sent.
module SpotifyPlayerToolTestHelper
  # Builds a bound tool for `kind` against the `spotify_player` fixture. The
  # fake service supplies a fixed OAuth token and composes a real
  # `Oauth::Client` (exactly as `OauthService#client` does) backed by a test
  # adapter. `stub_block` receives a Faraday stubs object.
  def expose_spotify_player_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:authorized_token) { "test-access-token" }
    fake_service.define_singleton_method(:client) do |base_url: "https://api.spotify.com/v1"|
      @oauth_client ||= begin
        conn = Faraday.new(base_url) do |f|
          f.request :json
          f.response :json, content_type: /\bjson$/
          f.adapter :test, &stub_block
        end
        Oauth::Client.new(base_url: base_url, token_source: fake_service, connection: conn)
      end
    end

    klass = ApplicationTool.expose_for(services(:spotify_player)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test
  # adapter. Player control commands return 204 No Content.
  def spotify_player_response(status: 204, headers: {})
    [ status, headers, "" ]
  end
end
