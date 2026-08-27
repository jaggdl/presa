# frozen_string_literal: true

require "faraday"
require "json"

module Gmail
  # Abstract base for all Gmail tools. Not exposed directly. Resolves the bound
  # OAuth service's live access token (refreshing it if needed) and issues
  # authorized requests against the Gmail API.
  class Base < ApplicationTool
    service_kind :gmail
    abstract_tool true

    GMAIL_API = "https://gmail.googleapis.com"

    # Overridable in tests to inject a fake Faraday connection.
    def conn
      @conn ||= Faraday.new(url: GMAIL_API) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    end

    private

    # GET against the Gmail API, returning the parsed JSON body.
    def gmail_get(path, params: {})
      conn.get(path) do |req|
        req.headers["Authorization"] = "Bearer #{authorized_token}"
        req.params.update(params)
      end.body
    end

    # POST against the Gmail API, sending `body` as JSON. Returns the parsed
    # JSON body.
    def gmail_post(path, body:)
      conn.post(path) do |req|
        req.headers["Authorization"] = "Bearer #{authorized_token}"
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end.body
    end

    def authorized_token
      service.authorized_token
    end
  end
end
