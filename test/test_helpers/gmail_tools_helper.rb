# frozen_string_literal: true

# Shared support for testing Gmail tools. Each tool test file in
# `test/tools/gmail/` includes this module to get a bound tool whose API calls
# go through an `Oauth::Client` with a Faraday test adapter (no network) and
# whose OAuth token comes from a fake service. The helper lets the test stub
# responses per path and inspect the Authorization header that was sent.
module GmailToolTestHelper
  # Builds a bound tool for `kind` against the `gmail` fixture. The fake
  # service supplies a fixed OAuth token and composes a real `Oauth::Client`
  # (exactly as `OauthService#client` does) backed by a test adapter.
  # `stub_block` receives a Faraday stubs object so the test can register
  # `stub.get("/gmail/v1/...") { |env| [...response...] }`.
  def expose_gmail_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:authorized_token) { "test-access-token" }
    fake_service.define_singleton_method(:client) do |base_url: "https://gmail.googleapis.com/gmail/v1"|
      conn = Faraday.new(base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter :test, &stub_block
      end
      Oauth::Client.new(base_url: base_url, token_source: fake_service, connection: conn)
    end

    klass = ApplicationTool.expose_for(services(:gmail)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test adapter.
  def gmail_json_response(body, status: 200)
    [ status, { "content-type" => "application/json" }, body.is_a?(String) ? body : JSON.generate(body) ]
  end
end
