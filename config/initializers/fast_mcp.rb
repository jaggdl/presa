# frozen_string_literal: true

# FastMcp - Model Context Protocol for Rails
# This initializer sets up the MCP middleware in your Rails application.
#
# In Rails applications, you can use:
# - ActionTool::Base as an alias for FastMcp::Tool
# - ActionResource::Base as an alias for FastMcp::Resource
#
# All your tools should inherit from ApplicationTool which already uses ActionTool::Base,
# and all your resources should inherit from ApplicationResource which uses ActionResource::Base.

# Mount the MCP middleware in your Rails application
# You can customize the options below to fit your needs.
require "fast_mcp"

FastMcp.mount_in_rails(
  Rails.application,
  name: Rails.application.class.module_parent_name.underscore.dasherize,
  version: "1.0.0",
  path_prefix: "/mcp", # This is the default path prefix
  messages_route: "messages", # This is the default route for the messages endpoint
  sse_route: "sse", # This is the default route for the SSE endpoint
  # Add allowed origins below, it defaults to Rails.application.config.hosts
  # allowed_origins: ['localhost', '127.0.0.1', '[::1]', 'example.com', /.*\.example\.com/],
  # localhost_only: true, # Set to false to allow connections from other hosts
  # whitelist specific ips to if you want to run on localhost and allow connections from other IPs
  # allowed_ips: ['127.0.0.1', '::1'],
  # authenticate: true,       # Uncomment to enable authentication
  # auth_token: 'your-token', # Required if authenticate: true
) do |server|
  Rails.application.config.after_initialize do
    # FastMcp will automatically discover and register:
    # - All classes that inherit from ApplicationTool (which uses ActionTool::Base)
    # - All classes that inherit from ApplicationResource (which uses ActionResource::Base)
    server.register_tools(*ApplicationTool.descendants)
    server.register_resources(*ApplicationResource.descendants)
    # alternatively, you can register tools and resources manually:
    # server.register_tool(MyTool)
    # server.register_resource(MyResource)
    server.filter_tools do |_request, tools|
      next [] unless Current.workspace

      # Generic tools (no service_kind) are exposed to every workspace.
      generic = tools.select { |tool| tool.service_kind.blank? }

      # One bound tool class per handler per service instance configured on the
      # workspace, restricted to the tools allowed for that service.
      bound = Current.workspace.workspace_services.includes(:service).flat_map do |wc|
        ApplicationTool.expose_for(wc.service).select { |tool| wc.tool_allowed?(tool.tool_key) }
      end

      generic + bound
    end
  end
end
