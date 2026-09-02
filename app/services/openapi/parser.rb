# frozen_string_literal: true

require "json"
require "net/http"
require "openapi_parser"
require "psych"
require "uri"

module Openapi
  # Raised when an OpenAPI-backed tool call fails at the HTTP layer.
  class ApiError < StandardError; end

  # Loads and validates an OpenAPI 3.x document before Presa turns it into a
  # service. Input may be a URL (fetched over HTTP/HTTPS, capped in size) or a
  # pasted raw JSON/YAML string.
  class Parser
    # Largest spec body we are willing to fetch from a URL (20 MB).
    MAX_SPEC_BYTES = 20 * 1024 * 1024
    # Longest a spec fetch is allowed to take.
    FETCH_TIMEOUT = 30

    class Error < StandardError; end

    # Parses the given input into `[raw_hash, OpenAPIParser root]`. `source` is
    # `"url"` or `"raw"`; `input` is the URL or the pasted content. Raises
    # `Openapi::Parser::Error` for anything unparseable.
    def self.parse(source:, input:)
      text = source.to_s == "url" ? fetch(input) : input.to_s
      raw = parse_text(text)
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      [ raw, root ]
    rescue Openapi::Parser::Error
      raise
    rescue StandardError => e
      raise Error, "Could not parse the OpenAPI document: #{e.message}"
    end

    # Fetches a spec URL, following redirects, capped in both size and time.
    def self.fetch(url)
      uri = URI(url.to_s.strip)
      raise Error, "Spec URL must be http(s)" unless %w[http https].include?(uri.scheme)

      body = nil
      redirects = 0
      while uri
        raise Error, "Too many redirects fetching spec" if (redirects += 1) > 5

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: FETCH_TIMEOUT, read_timeout: FETCH_TIMEOUT) do |http|
          req = Net::HTTP::Get.new(uri.request_uri)
          req["User-Agent"] = "Presa-OpenAPI/1"
          http.request(req)
        end

        case response
        when Net::HTTPRedirection
          location = response["location"]
          raise Error, "Spec fetch returned a redirect without a location" if location.blank?

          uri = uri.merge(location)
        when Net::HTTPSuccess
          body = response.body
          raise Error, "Spec content exceeds 20 MB" if body.bytesize > MAX_SPEC_BYTES

          break
        else
          raise Error, "Couldn't fetch the spec URL (HTTP #{response.code})"
        end
      end
      body
    end

    # Parses raw JSON or YAML text into a Hash. YAML tolerates anchors/aliases,
    # which hand-written OpenAPI specs commonly use.
    def self.parse_text(text)
      raise Error, "No spec content provided" if text.blank?

      json = text.strip.start_with?("{") ? safe_json(text) : nil
      return json if json

      yaml = Psych.safe_load(text, permitted_classes: [ Date, Time ], aliases: true)
      return yaml if yaml.is_a?(Hash)

      raise Error, "Spec must be a JSON or YAML object"
    rescue Psych::Exception => e
      raise Error, "Spec isn't valid JSON or YAML: #{e.message}"
    end

    # Confirms the parsed hash is an OpenAPI 3.x document (not Swagger 2.0).
    def self.validate!(raw)
      version = raw["openapi"].to_s
      return if version.start_with?("3.")

      if raw["swagger"].present? || raw.key?("openapi")
        raise Error, "Only OpenAPI 3.x documents are supported (found \"#{version.presence || "unknown"}\")"
      end

      raise Error, "That doesn't look like an OpenAPI document (missing `openapi` version)"
    end

    def self.safe_json(text)
      JSON.parse(text)
    rescue JSON::ParserError
      nil
    end
    private_class_method :safe_json
  end
end