# frozen_string_literal: true

namespace :registry do
  namespace :openapi do
    # Backfills the category on already-installed OpenapiKinds that came from a
    # registry preset. Presets install with their declared `category`
    # (e.g. `productivity` for Figma), but kinds installed before that change
    # kept the `general` default. For each `registry/openapi/*.yml` preset this
    # sets the category on every installed kind whose namespace matches, so the
    # new-service page (and future picker grouping) labels them correctly.
    #
    # Idempotent: re-running only touches kinds whose category still differs.
    desc "Backfill category on installed OpenapiKinds from their registry preset"
    task backfill_categories: :environment do
      updated = 0

      Registry::Openapi.presets.each do |preset|
        OpenapiKind.where(namespace: preset.namespace).each do |kind|
          next if kind.category == preset.category

          kind.update!(category: preset.category)
          updated += 1
          puts "#{kind.namespace}: category -> #{preset.category}"
        end
      end

      puts "#{updated} installed kind(s) updated."
    end

    # Backfills the OAuth provider override on already-installed OpenapiKinds
    # that came from a registry preset declaring `oauth_provider` (e.g. a
    # Google-API spec that should share the well-known "google" provider's
    # client credentials). Skips presets without the field; idempotent.
    desc "Backfill oauth_provider on installed OpenapiKinds from their registry preset"
    task backfill_oauth_providers: :environment do
      updated = 0

      Registry::Openapi.presets.each do |preset|
        next if preset.oauth_provider.blank?

        OpenapiKind.where(namespace: preset.namespace).each do |kind|
          next if kind.read_attribute(:oauth_provider) == preset.oauth_provider

          kind.update!(oauth_provider: preset.oauth_provider)
          updated += 1
          puts "#{kind.namespace}: oauth_provider -> #{preset.oauth_provider}"
        end
      end

      puts "#{updated} installed kind(s) updated."
    end

    # Rebuilds already-installed OpenapiKinds from their on-disk registry
    # preset, so edits to `registry/openapi/*.yml` (title, category, spec_url,
    # base_url, health_op, oauth_provider, description) and the checked-in icon
    # take effect on existing kinds. Regenerates the definition from spec_url,
    # updates the scalar fields, and refreshes the attached icon (the previously
    # attached blob is purged first, so a replaced file — e.g. SVG -> PNG —
    # doesn't stick).
    #
    # Run for a single preset with `NAMESPACE=youtube_analytics`, or omit to
    # reprocess every preset that has an installed kind. Idempotent.
    desc "Reprocess installed OpenapiKinds from their registry preset"
    task reprocess: :environment do
      presets = Registry::Openapi.presets
      presets = presets.select { |preset| preset.namespace == ENV["NAMESPACE"] } if ENV["NAMESPACE"].present?

      updated = 0
      presets.each do |preset|
        OpenapiKind.where(namespace: preset.namespace).each do |kind|
          rebuilt = Registry::Openapi.send(:build_kind, preset, kind.team)
          kind.assign_attributes(
            rebuilt.attributes.slice("title", "category", "description", "base_url",
                                     "spec_url", "definition", "health_op", "oauth_provider")
          )
          kind.icon.purge if kind.icon.attached?
          Registry::Openapi.send(:attach_preset_icon, kind, preset)
          kind.save!
          updated += 1
          puts "#{kind.namespace}: reprocessed"
        end
      end

      puts "#{updated} installed kind(s) reprocessed."
    end
  end
end
