# frozen_string_literal: true

module Seerr
  # Returns the number of requests on the instance broken down by status.
  class GetRequestCountsTool < Base
    description "Get Seerr request counts by status (total, pending, approved, available, etc.)"
    kind :get_request_counts

    def call
      seerr_get("/request/count")
    end
  end
end