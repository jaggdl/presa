# frozen_string_literal: true

module Tools
  module Jellyfin
    # Lists all user media folders (libraries) on the Jellyfin server.
    class GetLibraries < Base
      description "List media libraries on the Jellyfin server"
      kind "get_libraries"

      def call
        service.get("/Library/MediaFolders")
      end
    end
  end
end
