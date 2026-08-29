# frozen_string_literal: true

module Notion
  # Searches Notion for pages and databases by title, optionally narrowed to a
  # single object type and sorted by last edit time.
  class SearchTool < Base
    description "Search Notion pages and databases by title, optionally filtered by object type and sorted by last edit time"

    arguments do
      optional(:query).filled(:string).description("Free-text search term matching page/database titles")
      optional(:object_type).filled(:string).description("Restrict results to one object type: 'page' or 'database'")
      optional(:sort_direction).filled(:string).description("Sort by last edit time: 'ascending' or 'descending'")
      optional(:cursor).filled(:string).description("Pagination cursor from a previous result's next_cursor")
      optional(:page_size).filled(:integer, gt?: 0, lteq?: 100).description("Maximum number of results to return (default 100)")
    end

    def call(query: nil, object_type: nil, sort_direction: nil, cursor: nil, page_size: nil)
      body = {}
      body[:query] = query if query.present?
      if object_type.present?
        raise ArgumentError, "object_type must be 'page' or 'database'" unless %w[page database].include?(object_type)

        body[:filter] = { value: object_type, property: "object" }
      end
      if sort_direction.present?
        raise ArgumentError, "sort_direction must be 'ascending' or 'descending'" unless %w[ascending descending].include?(sort_direction)

        body[:sort] = { direction: sort_direction, timestamp: "last_edited_time" }
      end
      body[:start_cursor] = cursor if cursor.present?
      body[:page_size] = page_size if page_size.present?

      notion_post("search", body: body)
    end
  end
end
