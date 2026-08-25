# frozen_string_literal: true

module Tools
  module Jellyfin
    # Gets public information about the Jellyfin server.
    class GetPublicSystemInfo < Base
      description "Get public information about the Jellyfin server"
      kind "get_public_system_info"

      def call
        service.get("/System/Info/Public", auth: false)
      end
    end
  end
end
