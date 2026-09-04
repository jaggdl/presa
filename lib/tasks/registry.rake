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
  end
end
