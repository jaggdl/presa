# Workspace

Expose one or more of your workspaces as MCP tools so an agent can read and
manage them directly — without you needing to open the web UI.

## Configuration

Choose the workspace(s) this service may manage. A Workspace service is scoped
strictly to your own workspaces: it can only read or change the workspaces you
select, and never another user's data.

### Which workspace(s) to manage

Check the workspaces you want the agent to be able to view and control. You can
grant access to one or several.

## What it can do

- Update a workspace's **name** and **description**.
- **Connect** a service to a workspace and **disconnect** it again.
- Read and set which **tools** a connected service is allowed to expose in a
  workspace.
- Read the workspace's **run history** (recent tool invocations).
- List a workspace's **current services** and the services that could be added.

The tools act on the same models and guards the web UI uses, so nothing it does
is outside what you could do yourself.