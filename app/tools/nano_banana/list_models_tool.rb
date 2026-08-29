# frozen_string_literal: true

module NanoBanana
  # Lists the image models the configured Nano Banana service can generate with.
  # Agents call this to discover valid ids to pass to `generate_image`/`edit_image`.
  class ListModelsTool < Base
    description "List the Nano Banana image models available to this service. Returns each model's id (passable to generate_image/edit_image), label, and whether it is the default."

    arguments do
    end

    def call
      service.list_models
    end
  end
end
