class RenameWorkspaceServiceToWorkplaceAdmin < ActiveRecord::Migration[8.1]
  def up
    Service.where(type: "Services::Workspace").update_all(type: "Services::WorkplaceAdmin")
    # Historical invocations recorded the old MCP tool names
    # ("workspace_connect_service", ...); rewrite them so the invocation log
    # matches the current Workplace Admin tool names.
    ToolInvocation.where("substr(tool_name, 1, 10) = 'workspace_'")
                  .update_all(%(tool_name = 'workplace_admin_' || substr(tool_name, 11)))
  end

  def down
    ToolInvocation.where("substr(tool_name, 1, 16) = 'workplace_admin_'")
                  .update_all(%(tool_name = 'workspace_' || substr(tool_name, 17)))
    Service.where(type: "Services::WorkplaceAdmin").update_all(type: "Services::Workspace")
  end
end
