# Adding Services and Tools

This guide explains how to add a new service kind and its MCP tools to Presa. It assumes you understand the core domain described in the [README](../README.md).

## Concepts

| Term | What it is | Where it lives |
| --- | --- | --- |
| **Service** | A configured integration instance (user-owned, shared across a user's workspaces) | `app/models/services/<kind>.rb`, STI subclass of `Service` |
| **Tool** | An MCP capability backed by a service | `app/tools/<kind>/…`, subclasses of `ApplicationTool` |
| **Workspace** | Named scope that links services to MCP clients | database table + `WorkspaceService` join |

A **service kind** (e.g. `github`) is defined by a pair:

1. An STI model class under `app/models/services/` (holds config schema + validations).
2. A namespace of tool classes under `app/tools/<kind>/` (the MCP handlers).

## Model-side: the service

Create `app/models/services/<kind>.rb`:

```ruby
module Services
  class Slack < Service
    kind :slack                       # machine name of the kind (default: derived from class name)

    # Declare each config field. `required: true` enforces presence.
    # `secret: true` marks the field as a password input in the UI.
    # `default:` seeds the value when a service is created.
    config_field :bot_token, required: true, secret: true
    config_field :team, required: true
    config_field :base_url, default: "https://slack.com/api"
  end
end
```

### The `config_field` DSL

Defined on `ApplicationRecord`-derived `Service` (`app/models/service.rb`):

- `:field` — the config key name.
- `required: true/false` — if required, the service validates the field is present before saving.
- `secret: true` — rendered as a password field in the service form.
- `default: …` — applied to new services (merged under whatever the user types).

Config is stored as an **encrypted JSON column** (`encrypts :config`) and is read with indifferent access: `service.config[:token]` and `service.config["token"]` both work.

### Registration

`Service.kinds` / `Service.class_for_kind` are derived from `Service.descendants` that declare config fields, so a new subclass registers automatically — no central registry to edit.

To add new config fields later, just add more `config_field` lines. (You may want a data migration to backfill `default`s for existing rows.)

## Tool-side: the MCP handlers

Create `app/tools/<kind>/`:

1. **Base handler** — `app/tools/<kind>/base.rb`. Abstract, declares the service kind it targets:

```ruby
module Tools
  module Slack
    class Base < ApplicationTool
      service_kind :slack
      abstract_tool true       # not exposed directly
    end
  end
end
```

2. **Concrete tools** — e.g. `app/tools/slack/post_message.rb`:

```ruby
require "net/http"

module Tools
  module Slack
    class PostMessage < Base
      description "Post a message to a Slack channel"
      kind :post_message

      arguments do
        required(:channel).filled(:string).description("Channel to post to")
        required(:text).filled(:string).description("Message text")
      end

      def call(channel:, text:)
        service = Service.find(self.class.service_id)   # bound per instance

        uri = URI("#{service.config[:base_url]}/chat.postMessage")
        # ... use service.config[:token] ...
      end
    end
  end
end
```

### Key DSL methods (on `ApplicationTool`)

- `service_kind :slack` — which service kind this tool runs against.
- `kind :post_message` — the machine name of the tool (see MCP naming below).
- `abstract_tool true` — marks a base class so it is never exposed directly.
- `description "…"`, `arguments do … end` — the fast-mcp/MCP schema DSL.
- `def call(...)` — the handler. Reads the bound service via `self.class.service_id`.

### Discovering the bound service

When tools are exposed, `ApplicationTool.expose_for(service)` builds a dynamic subclass per (handler × service instance) and sets `service_id` on it. Inside `call`, resolve config with:

```ruby
service = Service.find(self.class.service_id)
service.config[:token]
```

This reads config at call time, so editing a service's credentials takes effect immediately.

### MCP tool naming

Exposed MCP tool names are built as `<kind>_<service_kind>_<service_name_slug>`. For a GitHub service named **"Personal"**, a tool `kind :list_issues` becomes `list_issues_github_personal`. Two GitHub services named "Prod" / "Staging" produce `list_issues_github_prod` and `list_issues_github_staging` — distinct tools, each bound to its own config.

## Wiring / refresh

Tool exposure is driven by `config/initializers/fast_mcp.rb`:

```ruby
server.filter_tools do |_request, tools|
  next [] unless Current.workspace

  generic = tools.select { |tool| tool.service_kind.blank? }
  bound   = Current.workspace.services.flat_map { |service| ApplicationTool.expose_for(service) }
  generic + bound
end
```

`config/initializers/fast_mcp_refresh.rb` bypasses fast-mcp's filtered-copy cache so the tool list is rebuilt from `Current.workspace.services` on every request. As a result:

- Creating/editing/deleting a **service** or re-linking a **workspace** is reflected immediately.
- Adding a new **tool class** requires the code to be loaded (dev server restart or reload), but is then picked up per request.

## Checklist

To add a new kind, `kind`:

1. Create `app/models/services/<kind>.rb` with `kind :kind` + `config_field`s.
2. Create `app/tools/<kind>/base.rb` with `service_kind :kind; abstract_tool true`.
3. Create `app/tools/<kind>/<tool>.rb` handlers.
4. (If needed) a data migration for default config on existing rows.
5. Add tests under `test/models/` (service config/validation) and, where useful, controller coverage. `test/models/application_tool_test.rb` shows how to assert `handlers_for` / `expose_for` output.