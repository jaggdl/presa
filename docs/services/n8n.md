# n8n

Expose the tools of an n8n MCP server endpoint in a workspace, so workflows you have running on n8n Cloud or a self-hosted instance become callable as workspace tools.

## Configuration

This service kind accepts the following configuration fields:

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `base_url` | yes | no | — | The base URL of the n8n MCP server endpoint you want to reach, e.g. `https://your-instance.n8n.cloud/mcp/` for n8n Cloud or `https://<your-host>/mcp/` for a self-hosted instance. The endpoint is exposed per instance via n8n's MCP Server Trigger, so the URL you enter must match your specific deployment; there is no global/shared n8n MCP URL. |
| `api_key` | yes | yes | — | The API key n8n uses to authenticate MCP clients (created in your n8n instance under Settings → MCP). Requests are authenticated by sending it in the `Authorization: Bearer <api_key>` header. |