# frozen_string_literal: true

# Shared support for testing Google Analytics tools. Each tool test file in
# `test/tools/google_analytics/` includes this module to get a bound tool whose
# API calls go through an `Oauth::Client` with a Faraday test adapter (no
# network) and whose OAuth token comes from a fake service. The helper lets
# the test stub responses per path/base and inspect the Authorization header
# and request body that were sent.
module GoogleAnalyticsToolTestHelper
  # Builds a bound tool for `kind` against the `google_analytics` fixture. The
  # fake service supplies a fixed OAuth token and composes a real
  # `Oauth::Client` per base URL (exactly as `OauthService#client` does) backed
  # by a test adapter. `stub_block` receives a Faraday stubs object so the test
  # can register `stub.get("/v1beta/...") { |env| [...response...] }` and
  # `stub.post("/v1beta/...:runReport") { |env| [...response...] }`.
  def expose_google_analytics_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:authorized_token) { "test-access-token" }
    fake_service.define_singleton_method(:client) do |base_url:|
      conn = Faraday.new(base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter :test, &stub_block
      end
      Oauth::Client.new(base_url: base_url, token_source: fake_service, connection: conn)
    end

    klass = ApplicationTool.expose_for(services(:google_analytics)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test adapter.
  def google_analytics_json_response(body, status: 200)
    [ status, { "content-type" => "application/json" }, body.is_a?(String) ? body : JSON.generate(body) ]
  end
end
