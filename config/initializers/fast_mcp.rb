# frozen_string_literal: true

# FastMcp - Model Context Protocol for Rails
# This initializer sets up the MCP middleware in your Rails application and
# registers every static tool / resource.
#
# Registration is what the MCP `tools/call` handler looks up tools by name
# (see FastMcp::Server#handle_tools_call). To register every tool, all
# `app/tools/**/*.rb` and `app/resources/**/*.rb` classes must be loaded first,
# because we register `ApplicationTool.descendants` / `ApplicationResource.descendants`
# and `descendants` only knows about *loaded* subclasses. In development
# (`config.eager_load = false`) those files are lazy-autoloaded, so without an
# explicit require here only a handful would be registered (e.g. just the ones
# that happened to load before boot) and every other tool would answer
# "Tool not found". We require them explicitly and re-register on each
# reload/train, so new tool files are picked up without a server restart.
require "fast_mcp"

FastMcp.mount_in_rails(
  Rails.application,
  name: Rails.application.class.module_parent_name.underscore.dasherize,
  version: "1.0.0",
  path_prefix: "/mcp", # This is the default path prefix
  messages_route: "messages", # This is the default route for the messages endpoint
  sse_route: "sse", # This is the default route for the SSE endpoint
) do |server|
  register = proc do
    Rails.root.glob("app/tools/**/*.rb").each { |file| require file }
    Rails.root.glob("app/resources/**/*.rb").each { |file| require file }
    server.register_tools(*ApplicationTool.descendants)
    server.register_resources(*ApplicationResource.descendants)
  end

  Rails.application.config.after_initialize(&register)
  Rails.application.config.to_prepare(&register)

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
