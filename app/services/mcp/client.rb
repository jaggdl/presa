# frozen_string_literal: true

require "faraday"
require "json"
require "securerandom"

module Mcp
  class Error < StandardError; end

  # Minimal outbound Model Context Protocol (MCP) client over Streamable HTTP.
  #
  # Presa's `fast-mcp` gem is server-side only, so proxying a *remote* MCP
  # server needs its own client. This speaks the JSON-RPC 2.0 subset the MCP
  # spec uses (`initialize`, `notifications/initialized`, `tools/list`,
  # `tools/call`) over Streamable HTTP, with the required `Mcp-Protocol-Version`
  # and `Mcp-Session-Id` headers.
  class Client
    DEFAULT_PROTOCOL_VERSION = "2025-03-26"

    def initialize(url:, headers: {}, protocol_version: DEFAULT_PROTOCOL_VERSION, connection: nil)
      @url = url
      @headers = headers || {}
      @protocol_version = protocol_version
      @session_id = nil
      @connection = connection
    end

    # Returns the remote server's tool list, parsed as JSON.
    def list_tools
      request("tools/list").fetch("result", {})
    end

    # Calls a remote tool. Returns the parsed JSON-RPC result.
    def call(name, arguments = {})
      request("tools/call", { name: name, arguments: arguments }).fetch("result", {})
    end

    private

    # One-shot helper that ensures the session is initialized before the first
    # protocol request (initialize -> notification) and reuses the session id.
    def request(method, params = {})
      session_ready!
      payload = { jsonrpc: "2.0", id: SecureRandom.uuid, method: method, params: params }
      handle_body(post(payload))
    end

    def session_ready!
      return if @session_ready

      init_payload = {
        jsonrpc: "2.0",
        id: SecureRandom.uuid,
        method: "initialize",
        params: {
          protocolVersion: @protocol_version,
          capabilities: {},
          clientInfo: { name: "presa", version: "1.0.0" }
        }
      }
      init_response = post(init_payload)
      @session_id ||= init_response.env.response_headers["mcp-session-id"]

      post(
        { jsonrpc: "2.0", method: "notifications/initialized", params: {} }
      )
      @session_ready = true
    end

    def handle_body(response)
      json = response.body.is_a?(String) ? JSON.parse(response.body) : response.body
      raise Error, json["error"].inspect if json["error"]

      json
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON-RPC response: #{e.message}"
    end

    def post(payload)
      conn.post("", JSON.generate(payload)) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "application/json, text/event-stream"
        req.headers["Mcp-Protocol-Version"] = @protocol_version
        req.headers["Mcp-Session-Id"] = @session_id if @session_id
      end
    end

    def conn
      @connection ||= Faraday.new(url: @url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 15
        faraday.options.open_timeout = 10
        @headers.each { |key, value| faraday.headers[key] = value }
      end
    end
  end
end
