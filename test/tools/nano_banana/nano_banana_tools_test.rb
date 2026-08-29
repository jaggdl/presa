# frozen_string_literal: true

require "test_helper"

class NanoBananaToolsTest < ActiveSupport::TestCase
  # Records the calls made to the service so we can assert arguments without
  # any network access.
  class FakeService
    attr_reader :calls

    def initialize
      @calls = []
    end

    def generate_image(prompt)
      @calls << { method: :generate_image, prompt: prompt }
      "data:image/png;base64,abc123"
    end

    def edit_image(prompt:, image_uri:)
      @calls << { method: :edit_image, prompt: prompt, image_uri: image_uri }
      "data:image/png;base64,edited"
    end
  end

  def expose_nano_banana_tool(kind)
    fake = FakeService.new
    klass = ApplicationTool.expose_for(services(:nano_banana)).find { |t| t.kind == kind }
    tool = klass.new
    tool.instance_variable_set(:@service, fake)
    [ tool, fake ]
  end

  test "tools are exposed for nano_banana services" do
    kinds = ApplicationTool.expose_for(services(:nano_banana)).map(&:kind)
    assert_includes kinds, "generate_image"
    assert_includes kinds, "edit_image"
  end

  test "generate_image calls the service with the prompt and returns the data URI" do
    tool, fake = expose_nano_banana_tool("generate_image")

    result = tool.call(prompt: "a cat wearing a top hat")

    assert_equal [ { method: :generate_image, prompt: "a cat wearing a top hat" } ], fake.calls
    assert_equal "data:image/png;base64,abc123", result
  end

  test "edit_image calls the service with the prompt and image uri" do
    tool, fake = expose_nano_banana_tool("edit_image")

    result = tool.call(prompt: "make it a dog", image_uri: "data:image/png;base64,xyz")

    assert_equal [ { method: :edit_image, prompt: "make it a dog", image_uri: "data:image/png;base64,xyz" } ], fake.calls
    assert_equal "data:image/png;base64,edited", result
  end
end
