module Tools
  module Jellyfin
    # Abstract base handler for all Jellyfin tools. Not exposed directly.
    class Base < ApplicationTool
      service_kind :jellyfin
      abstract_tool true
    end
  end
end
