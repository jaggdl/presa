# frozen_string_literal: true

module Services
  # Parallel Search's MCP endpoint, preconfigured as a preset `Services::Mcp`
  # subclass. Exposes Parallel's search toolset to the workspace. The only thing
  # the user must fill in is their Parallel Search API key.
  class Parallel < Mcp
    kind :parallel_search
    icon "parallel.png"

    preset
    config_field :api_key, required: true, secret: true

    mcp_url "https://search.parallel.ai/mcp"
    mcp_header "Authorization", "Bearer ${api_key}"
  end
end
