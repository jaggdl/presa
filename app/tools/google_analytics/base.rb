# frozen_string_literal: true

require "faraday"
require "json"

module GoogleAnalytics
  # Abstract base for all Google Analytics tools. Not exposed directly.
  # Resolves the bound OAuth service's live access token (refreshing it if
  # needed) and issues authorized requests against the Analytics Admin and
  # Data REST APIs, sharing the same OAuth flow as Gmail.
  class Base < ApplicationTool
    service_kind :google_analytics
    abstract_tool true

    ADMIN_API = "https://analyticsadmin.googleapis.com"
    DATA_API = "https://analyticsdata.googleapis.com"

    # A Faraday connection for the given API base URL. Overridable in tests to
    # inject a fake adapter.
    def conn(base_url)
      @conn ||= {}
      @conn[base_url] ||= Faraday.new(url: base_url) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    end

    private

    # GET against the given API base URL, returning the parsed JSON body.
    def ga_get(base_url, path, params: {})
      conn(base_url).get(path) do |req|
        req.headers["Authorization"] = "Bearer #{authorized_token}"
        req.params.update(params)
      end.body
    end

    # POST against the given API base URL, sending `body` as JSON. Returns the
    # parsed JSON body.
    def ga_post(base_url, path, body:)
      conn(base_url).post(path) do |req|
        req.headers["Authorization"] = "Bearer #{authorized_token}"
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end.body
    end

    def authorized_token
      service.authorized_token
    end

    # Normalizes a user-supplied property ID to the REST resource name, e.g.
    # 1234567 or "properties/1234567" => "properties/1234567".
    def property_resource_name(property_id)
      token = property_id.to_s.strip
      token = token.split("/").last if token.start_with?("properties/")
      raise ArgumentError, "Invalid property ID: #{property_id}" unless token.match?(/\A\d+\z/)

      "properties/#{token}"
    end

    # Recursively converts snake_case hash keys to the camelCase the Analytics
    # REST APIs expect (e.g. "filter_expression" => "filterExpression"). Keys
    # already in camelCase (no underscore) are left untouched, so callers may
    # pass either convention. String values are never altered.
    def camelize_keys_deep(value)
      case value
      when Hash
        value.each_with_object({}) { |(key, v), out| out[snake_to_camel(key)] = camelize_keys_deep(v) }
      when Array
        value.map { |v| camelize_keys_deep(v) }
      else
        value
      end
    end

    def snake_to_camel(key)
      text = key.to_s
      text.include?("_") ? text.camelize(:lower) : text
    end
  end
end
