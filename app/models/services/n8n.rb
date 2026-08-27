# frozen_string_literal: true

module Services
  # n8n's MCP endpoint, preconfigured as a preset `Services::Mcp` subclass.
  # n8n Cloud or self-hosted instances each expose their own MCP server via the
  # MCP Server Trigger, so the user supplies only the instance URL and an API
  # key and gets that instance's workflows exposed as workspace tools.
  class N8n < Mcp
    kind :n8n
    icon "n8n.png"
    category :automation

    preset
    config_field :base_url, required: true
    config_field :api_key, required: true, secret: true

    mcp_header "Authorization", "Bearer ${api_key}"

    # n8n has no preset URL; the user supplies the instance's MCP endpoint
    # via the `base_url` config field.
    def configured_url(cfg)
      cfg[:base_url]
    end
  end
end
