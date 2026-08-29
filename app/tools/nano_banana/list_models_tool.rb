# frozen_string_literal: true

module NanoBanana
  # Lists the image models the configured Nano Banana service can generate with.
  # Agents call this to discover valid ids to pass to `generate_image`/`edit_image`.
  class ListModelsTool < Base
    description "List the Nano Banana image model ids available to this service, queried live from the Gemini API. Call it to discover valid ids to pass as the model argument to generate_image/edit_image (the default model is gemini-3.1-flash-image)."

    arguments do
    end

    def call
      service.list_models
    end
  end
end
