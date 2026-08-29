# frozen_string_literal: true

module Notion
  # Queries a Notion database for its rows, optionally filtered and sorted.
  # Filters and sorts are Notion API objects: a filter is e.g. { "property":
  # "Status", "select": { "equals": "Done" } }, a sort is { "property": "Due",
  # "direction": "ascending" } (or a timestamp sort { "timestamp": "created_time",
  # "direction": "ascending" }).
  class QueryDatabaseTool < Base
    description "Query a Notion database's rows, optionally filtered and sorted"

    arguments do
      required(:database_id).filled(:string).description("The 32-hex-character database ID, optionally with dashes; a URL fragment works too")
      optional(:filter).hash.description("A Notion filter object, e.g. { 'property': 'Status', 'select': { 'equals': 'Done' } }")
      optional(:sorts).array(:hash).description("Notion sort objects, e.g. [{ 'property': 'Due', 'direction': 'ascending' }]")
      optional(:cursor).filled(:string).description("Pagination cursor from a previous result's next_cursor")
      optional(:page_size).filled(:integer, gt?: 0, lteq?: 100).description("Maximum number of rows to return (default 100)")
    end

    def call(database_id:, filter: nil, sorts: nil, cursor: nil, page_size: nil)
      body = {}
      body[:filter] = deep_stringify(filter) if filter
      body[:sorts] = deep_stringify(sorts) if sorts
      body[:start_cursor] = cursor if cursor.present?
      body[:page_size] = page_size if page_size.present?

      notion_post("databases/#{normalize_id(database_id)}/query", body: body)
    end
  end
end
