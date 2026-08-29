# frozen_string_literal: true

module NanoBanana
  # Edits an existing image based on a text prompt using Google's Nano Banana
  # model. The image may be a data URI or an http(s) URL; it is sent to Gemini
  # directly and returned edited as a data URI. Nothing is stored.
  class EditImageTool < Base
    description "Edit an existing image (via data URI or URL) with a text prompt using Google Nano Banana. Returns the edited image as a data URI."

    arguments do
      required(:image_uri).filled(:string).description("The image to edit: a data URI (data:image/...;base64,...) or an http(s) URL")
      required(:prompt).filled(:string).description("Text description of how to edit the image (max 1000 characters)")
    end

    def call(image_uri:, prompt:)
      service.edit_image(prompt: prompt, image_uri: image_uri)
    end
  end
end
