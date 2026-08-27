# MCP

Exposes tools from a remote [Model Context Protocol](https://modelcontextprotocol.io) server into your workspace — reuse any MCP integration (web search, docs, databases, and more) without writing code.

## Configuration

| Field | Required | Secret | Default | Description |
| ----- | -------- | ------ | ------- | ----------- |
| `url` | Yes | No | — | The remote MCP endpoint URL (a Streamable HTTP MCP endpoint, NOT stdio/npx). You must have the endpoint's URL; configure `headers` below for any auth. Example: a Parallel Search MCP endpoint like `https://search.parallel.ai/mcp`. |
| `headers` | No | No | `"{}"` | Optional extra HTTP headers as valid JSON, e.g. `{"Authorization": "Bearer <key>"}` for servers that require an API key. Must be valid JSON. |

Note: only Streamable HTTP MCP servers are supported — stdio/npx servers are not.