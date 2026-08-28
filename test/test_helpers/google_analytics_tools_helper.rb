# frozen_string_literal: true

# Shared support for testing Google Analytics tools. Each tool test file in
# `test/tools/google_analytics/` includes this module to get a bound tool whose
# API calls go through a Faraday test adapter (no network) and whose OAuth
# token comes from a fake service. The helper lets the test stub responses per
# path and inspect the Authorization header and request body that were sent.
module GoogleAnalyticsToolTestHelper
  # Builds a bound tool for `kind` against the `google_analytics` fixture. The
  # fake service supplies a fixed OAuth token, and the tool's Faraday connection
  # is swapped for a test adapter. `stub_block` receives a Faraday stubs object
  # so the test can register `stub.get("/v1beta/...") { |env| [...response...] }`
  # and `stub.post("/v1beta/...:runReport") { |env| [...response...] }`.
  def expose_google_analytics_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:authorized_token) { "test-access-token" }

    klass = ApplicationTool.expose_for(services(:google_analytics)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool.define_singleton_method(:conn) do |base_url|
      Faraday.new(base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter :test, &stub_block
      end
    end
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test adapter.
  def google_analytics_json_response(body, status: 200)
    [ status, { "content-type" => "application/json" }, body.is_a?(String) ? body : JSON.generate(body) ]
  end
end
