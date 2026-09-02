# frozen_string_literal: true

# Checked-in service presets: self-contained YAML files (one per service) under
# `registry/`. Each preset *kind* lives in its own subdirectory and gets its own
# loader namespace — `Registry::Openapi` reads `registry/openapi/*.yml` to seed
# reusable `OpenapiKind`s, future kinds (MCP, ...) follow the same pattern with
# their own namespace (e.g. `Registry::Mcp` reading `registry/mcp/*.yml`).
#
# - `Registry::Preset`        shared, abstract base for a single preset
# - `Registry::Openapi`       OpenAPI preset loader (registry/openapi/*.yml)
#   - `Registry::Openapi::Preset`   OpenAPI-specific preset, adds OpenapiKind fields
module Registry
  ICON_EXTENSIONS = %w[jpg jpeg png svg webp ico gif].freeze

  class << self
    def root
      Rails.root.join("registry")
    end

    def icons_dir
      root.join("icons")
    end
  end
end
