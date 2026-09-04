# frozen_string_literal: true

require "test_helper"

class RegistryOpenapiBackfillCategoriesTest < ActiveSupport::TestCase
  # Loads the registry rake task so it can be invoked in-process.
  def load_task
    Rails.application.load_tasks
  end

  setup do
    @team = teams(:one)
    load_task
  end

  teardown do
    Rake::Task["registry:openapi:backfill_categories"].reenable
  end

  # Simulates a kind that was installed before presets persisted their category,
  # i.e. one whose namespace matches a registry preset but kept the default.
  def kind_for(namespace)
    OpenapiKind.create!(
      team: @team,
      title: namespace,
      namespace: namespace,
      category: "general",
      definition: { "operations" => [], "operation_count" => 0, "tag_count" => 0 }
    )
  end

  test "backfill sets the preset category on an installed kind" do
    kind = kind_for("figma")
    assert_equal "general", kind.category

    Rake::Task["registry:openapi:backfill_categories"].invoke

    assert_equal "productivity", kind.reload.category
  end

  test "backfill is idempotent and skips kinds that already match" do
    kind = kind_for("immich")
    OpenapiKind.create!(team: @team, title: "x", namespace: "whatever",
                        category: "general",
                        definition: { "operations" => [], "operation_count" => 0, "tag_count" => 0 })

    Rake::Task["registry:openapi:backfill_categories"].invoke
    assert_equal "media", kind.reload.category

    Rake::Task["registry:openapi:backfill_categories"].reenable
    assert_difference -> { OpenapiKind.where(category: "general").count }, 0 do
      Rake::Task["registry:openapi:backfill_categories"].invoke
    end
  end

  test "backfill leaves a kind whose namespace is not a preset untouched" do
    wizard = OpenapiKind.create!(team: @team, title: "w", namespace: "custom_api",
                                 category: "general",
                                 definition: { "operations" => [], "operation_count" => 0, "tag_count" => 0 })

    Rake::Task["registry:openapi:backfill_categories"].invoke

    assert_equal "general", wizard.reload.category
  end
end
