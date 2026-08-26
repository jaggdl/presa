# Presa

Presa hosts [MCP](https://modelcontextprotocol.io) servers for your external AI clients. Each client authenticates with an API token, connects to a **workspace**, and gets a tailored set of **tools** that are dynamically backed by your configured **services**.

```
                        ┌──────────────────────────────────────────────┐
                        │                     Presa                   │
                        │                                              │
   external AI client   │   ┌──────────────┐   ┌───────────────┐      │
  (Claude, Cursor, ...) │   │  Workspace   │   │   Service     │      │
        │               │   │ ──────────── │   │ ───────────── │      │
        │  Authorization│   │  API token   │   │  kind+config  │      │
        │  Bearer mcp_  │   │  named scope │   │  (github,     │      │
        ▼               │   │              │   │   jellyfin,   │      │
  /mcp/sse ─────────────┼─▶ │       │      │   │   mcp, ...)   │      │
  (MCP over SSE)        │   └───────┼──────┘   └──────▲────────┘      │
        │               │           │  links        │                │
        │  tools/call   │   ┌───────▼──────┐   ┌──────┴───────┐       │
        ▼               │   │ workspace_   │   │ Tool (unit)  │       │
   tool result ─────────┼── │ services     │──▶│ backed by a  │       │
        ▲               │   │ (join)       │   │ service      │       │
        │               │   └──────────────┘   └──────▲───────┘       │
        │  tools/list   │                            │                │
        │  (per-workspace)                            │ calls out to  │
        └───────────────┼────────────────────────────┘  external API  │
                        │                    (GitHub, Jellyfin, remote MCP)
                        └──────────────────────────────────────────────┘
```

Each tool invocation (timestamp, tool, arguments, response, status, duration) is logged to the workspace, and the web UI surfaces each service's available tools and their input parameters.

## How it works

- **Workspace** — a named scope. MCP clients authenticate to a workspace with an opaque API token (`mcp_…`).
- **Service** — a configured integration instance (e.g. a GitHub account/credential). Services belong to a user and are shared across that user's workspaces via a join.
- **Tool** — an MCP capability built on top of a service. Each service kind registers its own set of tools.

When an MCP client connects, Presa derives that workspace's tool list from its linked services. Config (API keys, base URLs) is read at call time and encrypted at rest, and changes are picked up on the next request — no restarts required.

## Connecting a client

After signing in on the web UI, create a **workspace** and an **API token** for it, then wire the token into your MCP client.

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
2. The token is resolved to an active API token via its owning workspace.
3. That workspace's context is set for the duration of the request.
4. Only tools relevant to that workspace are exposed.

See [docs/adding-services-and-tools.md](docs/adding-services-and-tools.md) to add new service kinds and their tools.