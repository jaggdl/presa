# frozen_string_literal: true

require "faraday"
require "json"

module Services
  class Github < Service
    kind :github

    config_field :api_token, required: true, secret: true
    config_field :base_url, default: "https://api.github.com"

    # Perform a GET against the Github API.
    def get(path, headers: {})
      conn.get(path) do |req|
        req.headers["Accept"] = "application/vnd.github+json"
        req.headers["Authorization"] = "Bearer #{config[:api_token]}"
        headers.each { |key, value| req.headers[key] = value }
      end.body
    rescue StandardError => e
      { error: e.message }
    end

    private

    def conn
      @conn ||= Faraday.new(url: config[:base_url]) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
