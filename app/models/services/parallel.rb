# frozen_string_literal: true

module Services
  # Parallel Search's MCP endpoint, preconfigured as a preset `Services::Mcp`
  # subclass. Exposes Parallel's search toolset to the workspace. The endpoint
  # is public and requires no API key or headers.
  class Parallel < Mcp
    kind :parallel_search
    icon "parallel.png"

    preset

    mcp_url "https://search.parallel.ai/mcp"
  end
end
