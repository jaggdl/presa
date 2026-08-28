# frozen_string_literal: true

module Jellyfin
  # Lists all user media folders (libraries) on the Jellyfin server.
  class GetLibrariesTool < Base
    description "List media libraries on the Jellyfin server"

    def call
      service.get("/Library/MediaFolders")
    end
  end
end
