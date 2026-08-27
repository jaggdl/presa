# frozen_string_literal: true

module Services
  # GitHub's own MCP endpoint, preconfigured as a preset `Services::Mcp`
  # subclass. Exposes GitHub Copilot's toolset to the workspace. The only thing
  # the user must fill in is a GitHub Personal Access Token.
  class Github < Mcp
    kind :github
    icon "github.png"
    invert_icon

    preset
    config_field :api_token, required: true, secret: true

    mcp_url "https://api.githubcopilot.com/mcp/"
    mcp_header "Authorization", "Bearer ${api_token}"
  end
end