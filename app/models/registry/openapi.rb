# frozen_string_literal: true

require "stringio"
require "yaml"

module Registry
  # OpenAPI preset loader. Each file in `registry/openapi/*.yml` seeds a
  # reusable `OpenapiKind` (title, namespace, category, tags, spec URL, default
  # base URL, health-check op, description). They surface in the service
  # picker/search through a dynamic `Service` subclass per preset until the
  # kind-creation flow is wired up.
  module Openapi
    class << self
      def files
        dir = Preset.directory
        dir.directory? ? Dir[dir.join("*.yml")].sort : []
      end

      def presets
        files.filter_map { |path| find(File.basename(path, ".yml")) }
      end

      def find(namespace)
        path = Preset.directory.join("#{namespace}.yml")
        return nil unless path.file?

        Preset.new(namespace, YAML.safe_load_file(path))
      rescue Psych::SyntaxError
        nil
      end

      # Preset namespaces, appended to `Service.kinds` so they appear in the
      # picker and search alongside static and Openapi-generated kinds. A preset
      # that has already been installed (an `OpenapiKind` exists for its
      # namespace) is excluded — it's offered as a real kind instead.
      def kinds
        namespaces = presets.map(&:namespace)
        installed = OpenapiKind.where(namespace: namespaces).pluck(:namespace)
        namespaces - installed
      end

      # The dynamic `Service` subclass backing an OpenAPI preset kind, or nil
      # when no registry/openapi/<kind>.yml exists.
      def virtual_class_for(namespace)
        preset = find(namespace)
        return nil unless preset

        virtual_classes[preset.namespace] ||= build_virtual_class(preset)
      end

      # Installs a preset: fetches + parses its spec URL, persists the
      # `OpenapiKind` (with the preset's checked-in icon, not a host download),
      # and returns the saved kind. Raises `Openapi::Parser::Error` on spec
      # problems and `ActiveRecord::RecordNotFound` for an unknown preset; a
      # kind that fails validation is returned unsaved for the caller to read
      # its errors. Lives on the loader so the controller stays thin and a
      # future preset kind (MCP) gets its own installer here.
      def install(namespace, team:)
        preset = find(namespace)
        raise ActiveRecord::RecordNotFound, "Preset '#{namespace}' not found" unless preset

        kind = build_kind(preset, team)
        attach_preset_icon(kind, preset)
        kind.save
        kind
      end

      private

      def virtual_classes
        @virtual_classes ||= {}
      end

      def build_virtual_class(preset)
        Class.new(Service).tap do |klass|
          klass.config_kind = preset.namespace
          klass.config_display_name = preset.title
          klass.config_category = preset.category
          klass.config_icon = preset.icon_filename.presence
          klass.define_singleton_method(:description) { preset.description.presence }
          klass.define_singleton_method(:registry_preset?) { true }
        end
      end

      # Fetches + parses + validates the preset's spec URL, generates the
      # persisted definition, and builds the `OpenapiKind` record (not yet
      # saved).
      def build_kind(preset, team)
        raw, root = ::Openapi::Parser.parse(source: "url", input: preset.spec_url)
        ::Openapi::Parser.validate!(raw)
        definition = ::Openapi::Generator.generate(root, source_url: preset.spec_url)
        apply_credential_overrides!(definition, preset)

        OpenapiKind.new(
          team: team,
          title: preset.title,
          namespace: preset.namespace,
          category: preset.category,
          description: preset.description,
          base_url: preset.base_url.presence || definition["base_url"].to_s.presence,
          spec_url: preset.spec_url,
          definition: definition,
          health_op: preset.health_op
        )
      end

      # Rewrites a security scheme's slot in the generated definition to match
      # the preset's declared credential transmission, for specs whose scheme is
      # wrong against the real server (e.g. Jellyfin's `Authorization` -> the
      # actual `X-Emby-Token` header).
      def apply_credential_overrides!(definition, preset)
        override = preset.credential_override
        return unless override

        slot = definition.dig("security", override["scheme"])
        return unless slot.is_a?(Hash)

        slot["in"] = override["in"]
        slot["param_name"] = override["param_name"] if override["param_name"].present?
        slot["in_desc"] = override["param_name"] if override["param_name"].present?
        slot["kind"] = "apikey"
        slot["name"] ||= override["scheme"]
      end

      # Uses the preset's checked-in icon file in `registry/icons` as the kind's
      # image (rather than enqueuing a host download, whose default base URL for
      # a self-hosted preset usually isn't reachable from here).
      def attach_preset_icon(kind, preset)
        path = preset.icon_path
        return if path.blank? || kind.icon.attached?

        kind.icon.attach(io: StringIO.new(path.binread), filename: path.basename.to_s,
                         content_type: Marcel::MimeType.for(path) || "image/png")
      end
    end
  end
end
