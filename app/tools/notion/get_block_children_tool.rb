# frozen_string_literal: true

module Notion
  # Lists the immediate child blocks of a Notion page or block, optionally
  # paginated. Page through long documents by passing the previous result's
  # next_cursor.
  class GetBlockChildrenTool < Base
    description "List a Notion page or block's child blocks, optionally paginated"

    arguments do
      required(:block_id).filled(:string).description("The 32-hex-character block or page ID, optionally with dashes; a URL fragment works too")
      optional(:cursor).filled(:string).description("Pagination cursor from a previous result's next_cursor")
      optional(:page_size).filled(:integer, gt?: 0, lteq?: 100).description("Maximum number of blocks to return (default 100)")
    end

    def call(block_id:, cursor: nil, page_size: nil)
      params = {}
      params[:start_cursor] = cursor if cursor.present?
      params[:page_size] = page_size if page_size.present?

      notion_get("blocks/#{normalize_id(block_id)}/children", params: params)
    end
  end
end
