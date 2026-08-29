require "test_helper"
require "active_job/test_helper"

class DeleteTempImageJobTest < ActiveJob::TestCase
  test "removes the stored file" do
    filename = TempImageStore.save("bytes", mime: "image/png")

    assert TempImageStore.read(filename)
    DeleteTempImageJob.perform_now(filename)
    assert_nil TempImageStore.read(filename)
  end

  test "is a no-op for unknown files" do
    assert_nothing_raised { DeleteTempImageJob.perform_now("nope.png") }
  end
end
