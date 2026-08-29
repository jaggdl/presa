# frozen_string_literal: true

module Notion
  # Abstract base for all Notion tools. Not exposed directly. HTTP transport,
  # OAuth bearer-token injection, and the required `Notion-Version` header live
  # on the service (composed via `Oauth::Client`); this base only shapes
  # requests to the Notion API. Paths are relative to the service's API base
  # (`https://api.notion.com/v1`): a leading slash would make Faraday drop the
  # base path.
  class Base < ApplicationTool
    service_kind :notion
    abstract_tool true

    private

    # The Notion API's 32-hex-character resource ID for a page, database, or
    # block. Accepts a bare ID (with or without dashes) or a full notion.so
    # link, from which the trailing 32-hex token is extracted. Raises with a
    # helpful message when no valid ID can be found.
    def normalize_id(value)
      compact = value.to_s.strip.gsub("-", "")
      token = compact[/[0-9a-fA-F]{32}\z/]
      raise ArgumentError, "Invalid Notion ID: #{value}" unless token

      token
    end

    # Recursively normalizes hash keys to strings, since JSON.generate would
    # otherwise preserve symbol keys verbatim where the Notion API expects
    # string keys ("database_id" not :database_id).
    def deep_stringify(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), out| out[k.to_s] = deep_stringify(v) }
      when Array
        value.map { |v| deep_stringify(v) }
      else
        value
      end
    end

    # GET against the Notion API, returning the parsed JSON body.
    def notion_get(path, params: {})
      service.client.get(path, params: params)
    end

    # POST against the Notion API, sending `body` as JSON. Returns the parsed
    # JSON body.
    def notion_post(path, body:)
      service.client.post(path, body: body)
    end

    # PATCH against the Notion API, sending `body` as JSON. Returns the parsed
    # JSON body.
    def notion_patch(path, body:)
      service.client.patch(path, body: body)
    end
  end
end
