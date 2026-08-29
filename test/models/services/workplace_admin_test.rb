# frozen_string_literal: true

require "test_helper"

class Services::WorkplaceAdminTest < ActiveSupport::TestCase
  test "is a registered service kind" do
    assert_equal "workplace_admin", Services::WorkplaceAdmin.kind
    assert_includes Service.kinds, "workplace_admin"
  end

  test "requires at least one workspace" do
    service = Services::WorkplaceAdmin.new(name: "Admin", team: teams(:one))
    service.config = { workspace_ids: [] }
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("workspace") }
  end

  test "managed_workspaces scopes to the owner's configured workspaces" do
    service = Services::WorkplaceAdmin.new(name: "Admin", team: teams(:one))
    service.config = { workspace_ids: [ workspaces(:one).id, workspaces(:two).id ] }

    ids = service.managed_workspaces.pluck(:id)
    assert_includes ids, workspaces(:one).id
    assert_not_includes ids, workspaces(:two).id # foreign user's workspace dropped
  end

  test "manages_workspace? is false for a foreign workspace" do
    service = Services::WorkplaceAdmin.new(name: "Admin", team: teams(:one))
    service.config = { workspace_ids: [ workspaces(:two).id ] }
    assert_not service.manages_workspace?(workspaces(:two))
  end

  test "declares the Workplace Admin display name" do
    assert_equal "Workplace Admin", Services::WorkplaceAdmin.display_name
    assert_equal "Workplace Admin", Services::WorkplaceAdmin.new.display_name
  end
end
