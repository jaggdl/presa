require "test_helper"

class TeamTest < ActiveSupport::TestCase
  setup do
    @default_multi_tenant = Team.multi_tenant
  end

  teardown do
    Team.multi_tenant = @default_multi_tenant
  end

  test "has many users through memberships" do
    team = teams(:one)
    assert_includes team.users, users(:one)
  end

  test "validates name presence" do
    team = Team.new(name: nil)
    assert_not team.valid?
    assert_equal [ "can't be blank" ], team.errors[:name]
  end

  test "accepting_signups? and first_run? are true when no users exist" do
    Team.multi_tenant = false
    User.destroy_all

    assert Team.accepting_signups?
    assert Team.first_run?
  end

  test "single-tenant mode closes signups once users exist" do
    Team.multi_tenant = false

    assert_not Team.accepting_signups?
    assert_not Team.first_run?
  end

  test "multi-tenant mode always accepts signups" do
    Team.multi_tenant = true

    assert Team.accepting_signups?
    assert_not Team.first_run?
  end

  test "member? checks membership" do
    team = teams(:one)
    assert team.member?(users(:one))
    assert_not team.member?(users(:two))
    assert_not team.member?(nil)
  end
end
