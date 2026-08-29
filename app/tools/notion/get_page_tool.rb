# frozen_string_literal: true

module Notion
  # Retrieves a single page by its ID, returning its title block properties in
  # the `properties` field and its child blocks in `results` (via the
  # page-as-block shape). Use `get_block_children` to page through a page's
  # blocks.
  class GetPageTool < Base
    description "Retrieve a Notion page by ID, including its property values"

    arguments do
      required(:page_id).filled(:string).description("The 32-hex-character page ID, optionally with dashes; a URL fragment works too")
    end

    def call(page_id:)
      notion_get("pages/#{normalize_id(page_id)}")
    end
  end
end
