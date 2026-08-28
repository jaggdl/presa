# frozen_string_literal: true

require "test_helper"

class Services::WorkspaceTest < ActiveSupport::TestCase
  test "is a registered service kind" do
    assert_equal "workspace", Services::Workspace.kind
    assert_includes Service.kinds, "workspace"
  end

  test "requires at least one workspace" do
    service = Services::Workspace.new(name: "Admin", user: users(:one))
    service.config = { workspace_ids: [] }
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("workspace") }
  end

  test "managed_workspaces scopes to the owner's configured workspaces" do
    service = Services::Workspace.new(name: "Admin", user: users(:one))
    service.config = { workspace_ids: [ workspaces(:one).id, workspaces(:two).id ] }

    ids = service.managed_workspaces.pluck(:id)
    assert_includes ids, workspaces(:one).id
    assert_not_includes ids, workspaces(:two).id # foreign user's workspace dropped
  end

  test "manages_workspace? is false for a foreign workspace" do
    service = Services::Workspace.new(name: "Admin", user: users(:one))
    service.config = { workspace_ids: [ workspaces(:two).id ] }
    assert_not service.manages_workspace?(workspaces(:two))
  end
end
