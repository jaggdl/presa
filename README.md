# Presa

Presa is a **configurable [MCP](https://modelcontextprotocol.io) proxy**. Your external AI clients connect to it like any MCP server, and Presa proxies each request to whichever backend tools you've configured under a **workspace** — backed by your **services**.

```
     external AI client                     Presa (MCP proxy)
    (Claude, Cursor, ...)                  ┌──────────────────────┐
            │                              │                      │
            │  Authorization               │  ▸ Workspace         │
            │  Bearer mcp_                 │    API token         │
            ▼                              │    named scope       │
      /mcp/sse ──────────────────────────▶ │                      │
      (MCP over SSE)                       │  ▸ Services          │
            │                              │    github: <token>   │
            │  tools/list, tools/call      │    jellyfin: <key>   │
            ▼                              │    mcp: <remote>     │
         result  ◀─────────────────────────│                      │
   (MCP over SSE)                          └──────────────────────┘
                                             │  proxied calls to backend APIs
                                             ▼
                                   (GitHub, Jellyfin, remote MCP, ...)
```

Presa proxies each MCP request from the client to the backend service that backs the requested tool. Every invocation (timestamp, tool, arguments, response, status, duration) is logged to the workspace, and the web UI shows each service's available tools and their input parameters.

## How it works

- **Workspace** — a named scope. MCP clients authenticate and are proxied against a workspace with an opaque API token (`mcp_…`).
- **Service** — a configured backend integration (e.g. a GitHub account/credential) that provides tools. Services back the proxy's responses to a workspace.
- **Tool** — an MCP capability built on top of a service. Each service kind registers its own set of tools.

When an MCP client connects, Presa proxies the workspace's requests to the services configured for it. Config (API keys, base URLs) is read at call time and encrypted at rest, and changes are picked up on the next request — no restarts required.

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
