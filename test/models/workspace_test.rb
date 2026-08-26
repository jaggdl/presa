require "test_helper"

class WorkspaceTest < ActiveSupport::TestCase
  setup do
    @workspace = workspaces(:one)
  end

  test "share_code is generated once and persisted as a digest" do
    assert @workspace.share_code.present?
    assert @workspace.share_code_digest.present?
    refute_equal @workspace.share_code, @workspace.share_code_digest
  end

  test "reset_share_code! rotates the code and invalidates pending requests" do
    pending = BotAuthorization.initiate!(workspace: @workspace, name: "x")
    @workspace.reset_share_code!

    assert pending.reload.expired?
  end

  test "valid_share_code? matches the current code and rejects mismatches/blanks" do
    code = @workspace.reset_share_code!

    assert @workspace.valid_share_code?(code)
    refute @workspace.valid_share_code?("bogus")
    refute @workspace.valid_share_code?(nil)
  end
end
