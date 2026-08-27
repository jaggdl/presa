# Jellyfin

Interact with a [Jellyfin](https://jellyfin.org) media server: search your library, browse recent or on-deck items, and resume partially-watched movies and shows from anywhere.

## Configuration

| Field        | Required | Secret | Default                       | Description |
|--------------|----------|--------|-------------------------------|-------------|
| `api_key`    | yes      | yes    | —                             | Jellyfin API key sent via the `X-Emby-Token` header. Create one in the dashboard: Dashboard → API Keys → "+". |
| `base_url`   | no       | no     | `http://localhost:8096`       | Server's base URL as reachable from this app, e.g. `http://<host>:8096`. Use http or https with the correct port. |