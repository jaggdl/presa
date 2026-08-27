# frozen_string_literal: true

module Seerr
  # Approves or declines a pending media request.
  class UpdateRequestStatusTool < Base
    description "Approve or decline a Seerr media request by ID"
    kind :update_request_status

    arguments do
      required(:requestId).filled(:integer).description("ID of the request to update")
      required(:status).filled(:string).description("New status: 'approve' or 'decline'")
    end

    def call(requestId:, status:)
      service.post("/request/#{requestId}/#{status}")
    end
  end
end
