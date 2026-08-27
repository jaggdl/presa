# n8n

Expose the tools of an n8n MCP server endpoint in a workspace, so workflows you have running on n8n Cloud or a self-hosted instance become callable as workspace tools.

This connects to n8n's **instance-level MCP access** (Settings → Instance-level MCP), which creates a single MCP endpoint per instance with centralized authentication. After you enable it, each workflow you want exposed must be marked as **Available in MCP**; those workflows then become callable as workspace tools here.

> **Note:** this is distinct from n8n's MCP Server Trigger node, which exposes tools only from a single workflow. This service targets the instance-level endpoint instead.

## Configuration

This service kind accepts the following configuration fields:

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `base_url` | yes | no | — | The MCP server URL of your n8n instance, found under **Settings → Instance-level MCP → Connection details → Connect → API key** (n8n requires instance owner or admin permissions to enable this). See below for how the URL differs between instance-level access and the MCP Server Trigger node. |
| `api_key` | yes | yes | — | The bearer token n8n generates for your user account under **Settings → Instance-level MCP → Connection details → Connect → API key**. Requests are authenticated by sending it in the `Authorization: Bearer <api_key>` header. |

## Prerequisites

Before this service will surface any tools, your n8n instance needs both MCP access enabled **and** work to expose:

1. **Enable instance-level MCP** — as an instance owner or admin, go to **Settings → Instance-level MCP** and enable MCP access.
2. **Mark workflows as available in MCP** — a workflow is only callable once it's exposed. Only *published* workflows that contain a webhook, form, schedule, or chat trigger node are eligible. Turn on **Available in MCP** from the workflow editor menu, from the workflow card's **Enable MCP access** action, or via the **Workflows exposed** page under Settings → Instance-level MCP.

Here's a diagram of how an instance-level connection fits together:

```
n8n instance
├── Settings > Instance-level MCP  (enabled)
│     └── Connection > API key       <- base_url + api_key
├── workflow A....  Available in MCP  <-- exposed
└── workflow B....  (not exposed)
```

## Using a single workflow instead

If you only want to expose one specific workflow (rather than carefully curating which workflows are callable), n8n supports an **MCP Server Trigger node** placed inside that workflow. It exposes tools from only that workflow. This service can also reach such an endpoint — the difference is only in how the target was set up on the n8n side, not in the `base_url`/`api_key` fields (both use a bearer token over the same MCP protocol). Choose the server URL from whichever setup (instance-level or trigger node) you want to expose.