# frozen_string_literal: true

# Shared support for testing Google Places tools. Each tool test file in
# `test/tools/places/` includes this module to get a bound tool whose API calls
# go through a Faraday test adapter (no network) and whose API key comes from a
# fake service.
module PlacesToolTestHelper
  # Builds a bound tool for `kind` against the `places` fixture. The fake
  # service supplies the API key from config, and the tool's Faraday connection
  # is swapped for a test adapter. `stub_block` receives a Faraday stubs object.
  def expose_places_tool(kind, &stub_block)
    fake_service = Object.new
    fake_service.define_singleton_method(:config) { { "api_key" => "test-key" }.with_indifferent_access }

    klass = ApplicationTool.expose_for(services(:places)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake_service)
    tool.define_singleton_method(:conn) do
      Faraday.new("https://places.googleapis.com/v1") do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter :test, &stub_block
      end
    end
    tool
  end

  # Builds a [status, headers, body] response tuple for the Faraday test adapter.
  def places_json_response(body, status: 200, headers: {})
    [ status, { "content-type" => "application/json" }.merge(headers), body.is_a?(String) ? body : JSON.generate(body) ]
  end
end
