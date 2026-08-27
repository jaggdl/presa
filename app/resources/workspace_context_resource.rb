# frozen_string_literal: true

# Exposes the workspace's context (name, description, services and tool counts)
# over MCP as a resource — the same data as GET /bots/workspace.
class WorkspaceContextResource < ApplicationResource
  uri "workspace/context"
  resource_name "Workspace Context"
  description "The current workspace's name, description, services and tool counts"
  mime_type "text/plain"

  def content
    return "No workspace selected.\n" unless Current.workspace

    Current.workspace.workspace_context_text
  end
end
