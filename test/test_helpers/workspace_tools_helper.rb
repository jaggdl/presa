# frozen_string_literal: true

# Shared support for testing Workplace Admin management tools. Builds a bound
# tool for `kind` against the `workspace_manager` fixture (a
# Services::WorkplaceAdmin bound to user `one`'s workspaces) and returns it
# bound to a fake service snapshot.
module WorkspaceToolsTestHelper
  # Builds a bound tool for `kind` bound to the workspace_manager service and
  # the given managed workspaces (default: the workspaces(:one) fixture). The
  # tool's `service` is stubbed to return the fixture service record so scoping
  # helpers work against real database rows.
  def expose_workspace_tool(kind, workspaces: [ workspaces(:one) ])
    klass = ApplicationTool.expose_for(services(:workspace_manager)).find { |t| t.kind == kind }
    tool = klass.new
    service = services(:workspace_manager)
    service.config = { workspace_ids: workspaces.map(&:id) }
    tool.instance_variable_set(:@service, service)
    tool
  end
end
