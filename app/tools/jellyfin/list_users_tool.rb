# frozen_string_literal: true

module Jellyfin
  # Lists users on the Jellyfin server.
  class ListUsersTool < Base
    description "List users on the Jellyfin server"

    def call
      service.get("/Users")
    end
  end
end
