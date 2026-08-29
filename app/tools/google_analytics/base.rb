# frozen_string_literal: true

module GoogleAnalytics
  # Abstract base for all Google Analytics tools. Not exposed directly. HTTP
  # transport and OAuth bearer-token injection live on the service (composed
  # per API base URL via `Oauth::Client`); this base only shapes requests to
  # the Analytics Admin and Data REST APIs, sharing the same OAuth flow as
  # Gmail and Google Calendar.
  #
  # Analytics hits two hosts (admin + data), each with version-selected
  # resources (v1beta/v1alpha), so bases are host-only and paths keep the
  # leading slash plus version segment — unlike single-version kinds whose
  # tools use relative paths against a base that includes the version.
  class Base < ApplicationTool
    service_kind :google_analytics
    abstract_tool true

    ADMIN_API = "https://analyticsadmin.googleapis.com"
    DATA_API = "https://analyticsdata.googleapis.com"

    private

    # GET against the given API base URL, returning the parsed JSON body.
    def ga_get(base_url, path, params: {})
      service.client(base_url: base_url).get(path, params: params)
    end

    # POST against the given API base URL, sending `body` as JSON. Returns the
    # parsed JSON body.
    def ga_post(base_url, path, body:)
      service.client(base_url: base_url).post(path, body: body)
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
