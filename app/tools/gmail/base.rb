# frozen_string_literal: true

module Gmail
  # Abstract base for all Gmail tools. Not exposed directly. HTTP transport and
  # OAuth bearer-token injection live on the service (composed via
  # `Oauth::Client`); this base only shapes requests to the Gmail API. Paths
  # are relative to the service's API base (`.../gmail/v1`): a leading slash
  # would make Faraday drop the base path.
  class Base < ApplicationTool
    service_kind :gmail
    abstract_tool true

    private

    # GET against the Gmail API, returning the parsed JSON body.
    def gmail_get(path, params: {})
      service.client.get(path, params: params)
    end

    # POST against the Gmail API, sending `body` as JSON. Returns the parsed
    # JSON body.
    def gmail_post(path, body:)
      service.client.post(path, body: body)
    end
  end
end
