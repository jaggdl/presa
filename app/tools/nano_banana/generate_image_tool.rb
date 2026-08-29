# frozen_string_literal: true

module NanoBanana
  # Generates an image from a text prompt using Google's Nano Banana model and
  # returns it as a data URI.
  class GenerateImageTool < Base
    description "Generate an image from a text prompt with Google Nano Banana. Returns the image as a data URI."

    arguments do
      required(:prompt).filled(:string).description("Text description of the image to generate (max 1000 characters)")
    end

    def call(prompt:)
      service.generate_image(prompt)
    end
  end
end
