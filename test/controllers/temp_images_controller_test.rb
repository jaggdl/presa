# frozen_string_literal: true

require "test_helper"

class TempImagesControllerTest < ActionDispatch::IntegrationTest
  test "serves a stored image with its mime type" do
    filename = TempImageStore.save("hello-bytes", mime: "image/png")

    get "/temp_images/#{filename}"
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal "hello-bytes", response.body
  ensure
    TempImageStore.delete(filename) if filename
  end

  test "404s for an unknown filename" do
    get "/temp_images/nonexistent"
    assert_response :not_found
  end

  test "ignores path traversal attempts" do
    get "/temp_images/..%2F..%2FRakefile"
    assert_response :not_found
  end
end
