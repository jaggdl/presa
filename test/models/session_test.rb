require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "sets a default expiry on creation" do
    session = users(:one).sessions.create!

    assert_not_nil session.expires_at
    assert_in_delta Session::SLIDING_IDLE_TIMEOUT.from_now.to_i, session.expires_at.to_i, 10
  end

  test "is expired when expires_at passes" do
    session = users(:one).sessions.create!
    assert_not session.expired?

    session.update_columns(expires_at: 1.minute.ago)
    assert session.expired?
  end

  test "is not expired when expires_at is nil" do
    session = users(:one).sessions.create!
    session.update_columns(expires_at: nil)
    refute session.expired?
  end

  test "slide_expiry extends the lifetime when close to expiring" do
    session = users(:one).sessions.create!
    session.update_columns(expires_at: 10.minutes.from_now)

    assert_changes -> { session.expires_at.to_i }, to: Session::SLIDING_IDLE_TIMEOUT.from_now.to_i do
      session.slide_expiry!
    end
  end

  test "slide_expiry skips the write while plenty of life remains" do
    session = users(:one).sessions.create!

    assert_no_changes -> { session.expires_at.to_i } do
      session.slide_expiry!
    end
  end

  test "slide_expiry sets an expiry for sessions that never got one" do
    session = users(:one).sessions.create!
    session.update_columns(expires_at: nil)

    assert_changes -> { session.expires_at } do
      session.slide_expiry!
    end
  end
end
