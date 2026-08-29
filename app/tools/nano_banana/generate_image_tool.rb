# frozen_string_literal: true

module NanoBanana
  # Generates an image from a text prompt using Google's Nano Banana model and
  # returns it as a data URI.
  class GenerateImageTool < Base
    description "Generate an image from a text prompt with Google Nano Banana. Returns the image as a data URI."

    arguments do
      required(:prompt).filled(:string).description("Text description of the image to generate (max 1000 characters)")
      optional(:model).filled(:string).description("Nano Banana model id to use (default gemini-3.1-flash-image). Call the list_models tool to see available ids.")
    end

    def call(prompt:, model: nil)
      if model.present?
        service.generate_image(prompt, model: model)
      else
        service.generate_image(prompt)
      end
    end
  end
end
