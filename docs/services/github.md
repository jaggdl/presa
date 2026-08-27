# GitHub

GitHub's own MCP endpoint, preconfigured as a preset MCP service. Exposes GitHub Copilot's toolset (repository activity, issues, pull requests, and more) directly into your workspace without writing handlers.

## Configuration

This service kind accepts the following configuration field:

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `api_token` | yes | yes | — | GitHub Personal Access Token (PAT) used to authenticate with GitHub's MCP endpoint. Create one at GitHub → Settings → Developer settings → Personal access tokens, and grant it the scopes the tools need. |

The endpoint URL (`https://api.githubcopilot.com/mcp/`) and the `Authorization: Bearer` header are preconfigured; you only supply the token.