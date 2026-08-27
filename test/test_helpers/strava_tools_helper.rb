# frozen_string_literal: true

# Shared support for testing Strava tools. Each tool test file in
# `test/tools/strava/` includes this module to get a bound tool whose API calls
# go through a Faraday test adapter (no network) and whose OAuth token comes
# from a fake service.
module StravaToolTestHelper
  # Builds a bound tool for `kind` against the `strava` fixture. The fake
  # service supplies a fixed OAuth token, and the tool's Faraday connection is
  # swapped for a test adapter. `stub_block` receives a Faraday stubs object.
  def expose_strava_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:authorized_token) { "test-access-token" }

    klass = ApplicationTool.expose_for(services(:strava)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool.define_singleton_method(:conn) do
      Faraday.new("https://www.strava.com") do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter :test, &stub_block
      end
    end
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test adapter.
  def strava_json_response(body, status: 200)
    [ status, { "content-type" => "application/json" }, body.is_a?(String) ? body : JSON.generate(body) ]
  end
end
