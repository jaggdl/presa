# frozen_string_literal: true

module Services
  # Home Assistant's Model Context Protocol Server integration, preconfigured
  # as a preset `Services::Mcp` subclass. The endpoint lives at `/api/mcp` on
  # the Home Assistant instance and is authenticated with a Long-Lived Access
  # Token, so the user supplies only the instance URL and that token to expose
  # their Assist tools (lights, switches, sensors, to-do lists, ...) in a
  # workspace. See https://www.home-assistant.io/integrations/mcp_server/
  class HomeAssistant < Mcp
    kind :home_assistant
    icon "home_assistant.png"

    preset
    config_field :base_url, required: true
    config_field :access_token, required: true, secret: true

    mcp_header "Authorization", "Bearer ${access_token}"

    # Home Assistant has no preset URL; the user supplies the instance URL via
    # the `base_url` config field. The MCP server is served under `/api/mcp`.
    def configured_url(cfg)
      "#{cfg[:base_url].to_s.chomp('/')}/api/mcp"
    end
  end
end
