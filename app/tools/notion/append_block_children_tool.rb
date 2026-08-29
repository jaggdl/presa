# frozen_string_literal: true

module Notion
  # Appends blocks under a Notion page or other block. Each block follows the
  # Notion block object shape, e.g. { "object": "block", "type": "heading_2",
  # "heading_2": { "rich_text": [{ "type": "text", "text": { "content": "Hi" } }] } }.
  class AppendBlockChildrenTool < Base
    description "Append content blocks under a Notion page or block"

    arguments do
      required(:block_id).filled(:string).description("The 32-hex-character block or page ID whose children receive the blocks; a URL fragment works too")
      required(:children).array(:hash).description("Notion block objects to append, e.g. [{ 'object': 'block', 'type': 'heading_2', 'heading_2': { 'rich_text': [{ 'type': 'text', 'text': { 'content': 'Hi' } }] } }]")
    end

    def call(block_id:, children:)
      notion_patch("blocks/#{normalize_id(block_id)}/children", body: { children: deep_stringify(children) })
    end
  end
end
