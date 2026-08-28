require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "gets a default team when created" do
    user = User.create!(email_address: "new@example.com", password: "testtest")
    assert_equal 1, user.teams.count
  end
end
