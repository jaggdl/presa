# frozen_string_literal: true

module Seerr
  # Returns a single media request by ID.
  class GetRequestTool < Base
    description "Get details for a single Seerr media request by ID"
    kind :get_request

    arguments do
      required(:requestId).filled(:integer).description("ID of the request to fetch")
    end

    def call(requestId:)
      service.get("/request/#{requestId}")
    end
  end
end
