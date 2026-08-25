# Presa

Presa hosts [MCP](https://modelcontextprotocol.io) (Model Context Protocol) servers for your external AI clients. Each client authenticates with an API token, connects to a **workspace**, and gets a tailored set of **tools** that are dynamically backed by your configured **services**.

## How it works

- **Workspace** — a named scope. MCP clients authenticate to a workspace with an opaque API token (`mcp_…`).
- **Service** — a configured integration instance (e.g. a GitHub account/credential). Services belong to a user and are shared across that user's workspaces via a join (`workspace_services`).
- **Tool** — an MCP capability built on top of a service. Tools are Ruby classes, not database records. Each service kind registers its own set of tools.

When an MCP client connects, Presa derives that workspace's tool list from its linked services. Config (API keys, base URLs) is read at call time and encrypted at rest, and changes are picked up on the next request — no restarts required.

## Setup

Ruby and Rails are installed via [mise](https://mise.jdx.dev).

```sh
bin/setup                 # install deps, migrate
bin/dev                   # run web + css via Procfile.dev (default port 56666)
bin/rails test            # run the test suite
bin/rubocop               # lint
```

## Configuration

Secrets live in Rails credentials (`bin/rails credentials:edit`):

- `secret_key_base`
- `active_record_encryption` keys (added via `bin/rails db:encryption:init`)
- SQLite is used for the development database (see `config/database.yml`).

## MCP server

The MCP endpoint is mounted by `config/initializers/fast_mcp.rb` under `/mcp` (SSE at `/mcp/sse`). After signing in on the web UI, create a **workspace** and an **API token** for it, then wire the token into your MCP client.

Example `.mcp.json`:

```json
{
  "mcpServers": {
    "my-workspace": {
      "type": "sse",
      "url": "http://localhost:56666/mcp/sse",
      "headers": { "Authorization": "Bearer mcp_your_token" }
    }
  }
}
```

### Auth flow

1. The client sends `Authorization: Bearer <token>`.
2. `config/initializers/fast_mcp_jwt_auth.rb` resolves the token to an active `ApiToken` via its owning workspace.
3. `Current.workspace` is set for the duration of the request.
4. `filter_tools` (in `fast_mcp.rb`) exposes only tools relevant to that workspace.

See [docs/adding-services-and-tools.md](docs/adding-services-and-tools.md) to add new service kinds and their tools.

## Testing

```sh
bin/rails test
```

Model and controller tests live under `test/`. New services/tools should include coverage alongside.