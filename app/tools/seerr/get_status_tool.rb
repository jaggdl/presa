# frozen_string_literal: true

module Seerr
  # Reports the current Seerr instance status (version, update availability).
  class GetStatusTool < Base
    description "Get the Seerr instance's current status and version"
    kind :get_status

    def call
      service.get("/status")
    end
  end
end