require "test_helper"
require "active_job/test_helper"

class ExpireSessionsJobTest < ActiveJob::TestCase
  test "deletes expired sessions" do
    expired = users(:one).sessions.create!
    expired.update_columns(expires_at: 1.minute.ago)

    ExpireSessionsJob.perform_now

    assert_nil Session.find_by(id: expired.id)
  end

  test "keeps live sessions" do
    live = users(:one).sessions.create!
    live.update_columns(expires_at: 1.hour.from_now)

    ExpireSessionsJob.perform_now

    assert Session.find_by(id: live.id)
  end
end
