# frozen_string_literal: true

module NanoBanana
  # Edits an existing image based on a text prompt using Google's Nano Banana
  # model. The image may be passed as a data URI or URL (`image_uri`) or as raw
  # base64 data (`image`). Bytes handed in are stored briefly at a temporary URL
  # so the Gemini service can fetch them, then deleted in the background.
  class EditImageTool < Base
    description "Edit an existing image with a text prompt using Google Nano Banana. Provide the image as a data URI or URL (image_uri), or as base64 image data (image). Returns the edited image as a data URI."

    arguments do
      optional(:image_uri).filled(:string).description("The image to edit: a data URI (data:image/...;base64,...) or an http(s) URL")
      optional(:image).filled(:string).description("The image to edit as raw base64 image data (optionally data-URI prefixed).")
      required(:prompt).filled(:string).description("Text description of how to edit the image (max 1000 characters)")
      optional(:model).filled(:string).description("Nano Banana model id to use (default gemini-3.1-flash-image). Call the list_models tool to see available ids.")
    end

    def call(image_uri: nil, image: nil, prompt:, model: nil)
      provided = [ image_uri, image ].count(&:present?)
      raise "Provide exactly one of image_uri or image" unless provided == 1

      uri = image_uri.presence || temp_uri_from_image!(image)
      if model.present?
        service.edit_image(prompt: prompt, image_uri: uri, model: model)
      else
        service.edit_image(prompt: prompt, image_uri: uri)
      end
    end

    private

    def temp_uri_from_image!(image)
      input = image.to_s.strip
      if input.start_with?("data:")
        mime, _, b64 = input.partition(",")
        mime = mime.sub(/\Adata:/, "").split(";").first
      else
        mime, b64 = nil, input
      end
      mime = "image/png" if mime.blank? || !mime.start_with?("image/")
      bytes = Base64.decode64(b64)

      filename = TempImageStore.save(bytes, mime: mime)
      url_for(filename)
    end

    def url_for(filename)
      path = Rails.application.routes.url_helpers.temp_image_path(filename)
      DeleteTempImageJob.set(wait: 1.minute).perform_later(filename)
      "#{public_base_url}#{path}"
    end

    # The absolute origin used to build temp URLs the server (and remote callers)
    # can fetch: the configured BASE_URL when present, else the current request's
    # base URL, else a localhost fallback (fetches resolve inside the container).
    def public_base_url
      ENV["BASE_URL"].presence || "http://localhost:3000"
    end
  end
end
