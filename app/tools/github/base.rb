module Tools
  module Github
    # Abstract base handler for all GitHub tools. Not exposed directly.
    class Base < ApplicationTool
      service_kind :github
      abstract_tool true
    end
  end
end
