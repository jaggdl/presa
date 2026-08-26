# Development

Ruby and Rails are installed via [mise](https://mise.jdx.dev).

```sh
bin/setup               # install deps, migrate
bin/dev                 # run web + css via Procfile.dev (default port 56666)
bin/rails test          # run the test suite
bin/rubocop             # lint
bin/brakeman            # security scan
bin/bundler-audit       # dependency vulnerability scan
```

## Secrets & config

Secrets live in Rails credentials (`bin/rails credentials:edit`):

- `active_record_encryption` keys (added via `bin/rails db:encryption:init`)
- SQLite is used for the development database (see `config/database.yml`).

## MCP endpoint

The MCP endpoint is mounted by `config/initializers/fast_mcp.rb` under `/mcp` (SSE at `/mcp/sse`). After signing in on the web UI, create a **workspace** and an **API token** for it, then wire the token into your MCP client.

See [docs/adding-services-and-tools.md](adding-services-and-tools.md) to add new service kinds and their tools.