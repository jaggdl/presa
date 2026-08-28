require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "has many users through memberships" do
    team = teams(:one)
    assert_includes team.users, users(:one)
  end

  test "validates name presence" do
    team = Team.new(name: nil)
    assert_not team.valid?
    assert_equal [ "can't be blank" ], team.errors[:name]
  end
end
