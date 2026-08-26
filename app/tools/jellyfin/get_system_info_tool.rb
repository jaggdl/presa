# frozen_string_literal: true

module Jellyfin
  # Gets information about the Jellyfin server.
  class GetSystemInfoTool < Base
    description "Get information about the Jellyfin server"
    kind "get_system_info"

    def call
      service.get("/System/Info")
    end
  end
end
