# frozen_string_literal: true

module Notion
  # Creates a new page in Notion under a parent database or page. `properties`
  # must match the parent database's schema (e.g. for a database parent,
  # {"Name": {"title": [{"text": {"content": "Task"}}]}}). Child blocks, when
  # given, are appended under the new page.
  class CreatePageTool < Base
    description "Create a page in Notion under a database or page parent, setting its property values"

    arguments do
      required(:parent).hash.description("The page's parent, e.g. { 'database_id': '...' } or { 'page_id': '...' }")
      required(:properties).hash.description("Property values per the parent's schema, e.g. { 'Name': { 'title': [{ 'text': { 'content': 'Task' } }] } }")
      optional(:children).array(:hash).description("Content blocks to add under the new page, e.g. [{ 'object': 'block', 'type': 'paragraph', 'paragraph': { 'rich_text': [{ 'type': 'text', 'text': { 'content': 'Hello' } }] } }]")
    end

    def call(parent:, properties:, children: nil)
      body = { parent: deep_stringify(parent), properties: deep_stringify(properties) }
      body[:children] = children if children.present?

      notion_post("pages", body: body)
    end
  end
end
