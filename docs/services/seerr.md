# Seerr

Manage media requests with a [Seerr](https://seerr.io) request-manager server: search and discover movies and TV shows, submit and approve requests, and triage media issues.

## Configuration

| Field | Required | Secret | Default | Description |
|-------|----------|--------|---------|-------------|
| `api_key` | Yes | Yes | — | The Seerr API key. Create it in the Seerr web UI: Settings → General (or Settings → API Keys / "Copy API Key" depending on version). The app sends it via the `X-Api-Key` header. |
| `base_url` | No | No | `http://localhost:5055` | The server's base URL as reachable from this app, e.g. `http://<host>:5055`. Use http or https with the correct port. Do NOT append `/api/v1`. |

The API lives under `/api/v1`, which is handled automatically by the app.