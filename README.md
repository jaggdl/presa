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
      "url": "https://your-presa-instance.domain.com/mcp/sse",
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

## Self-hosting with Docker Compose

Deploy Presa behind your own host using the bundled production `Dockerfile` and a
`docker-compose.yml`. Below is the compose file used for a local/personal deployment.

```yaml
services:
  web:
    image: jaggdl/presa
    restart: unless-stopped
    ports:
      - "7753:80"
    environment:
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - BASE_URL=https://presa.jaggdl.com
    volumes:
      - presa-production:/rails/storage

volumes:
  presa-production:
```

### Run it

```sh
cd path/to/your/compose/dir
docker compose up -d
```

### Connect a client

Once the instance is up, create a **workspace** and an **API token** on the web UI as in the
[Connecting a client](#connecting-a-client) section, then wire the token into your MCP client.
On the host itself you can connect via `localhost`:

```json
{
  "mcpServers": {
    "my-workspace": {
      "type": "sse",
      "url": "http://localhost:7753/mcp/sse",
      "headers": { "Authorization": "Bearer mcp_your_token" }
    }
  }
}
```

> You can also connect via the public domain instead of `localhost`, e.g.
> `https://presa.example.com/mcp/sse`, which is what you'd point remote clients at.

### Configuration

| Variable             | Purpose                                                            |
| -------------------- | ------------------------------------------------------------------ |
| `RAILS_MASTER_KEY`   | Rails master key used to decrypt `config/credentials.yml.enc`. Must match the app's `config/master.key`; you can copy the repo's `config/master.key` into your deployment if you hold the seed. |
| `BASE_URL`           | Public URL of the instance (e.g. `https://presa.example.com`). Used to build absolute links and signing. |

Persist the encrypted `storage/` (attachments and uploads) via the `presa-production`
named volume, mounted at `/rails/storage`.

A minimal `.env` next to the compose file:

```
RAILS_MASTER_KEY=<your key>
BASE_URL=https://presa.example.com
```

### Updating

Pull the latest image, then recreate the container:

```sh
docker compose pull
docker compose down
docker compose up -d
```

## Development

See [docs/development.md](docs/development.md) for setup, commands, and config.
