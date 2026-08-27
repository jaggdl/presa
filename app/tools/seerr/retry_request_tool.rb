# frozen_string_literal: true

module Seerr
  # Retries a failed request by re-sending it to Radarr/Sonarr.
  class RetryRequestTool < Base
    description "Retry a failed Seerr media request"
    kind :retry_request

    arguments do
      required(:requestId).filled(:integer).description("ID of the failed request to retry")
    end

    def call(requestId:)
      service.post("/request/#{requestId}/retry")
    end
  end
end
