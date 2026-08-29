# frozen_string_literal: true

module Notion
  # Retrieves a Notion database by ID, including its title and property schema.
  class GetDatabaseTool < Base
    description "Retrieve a Notion database by ID, including its property schema"

    arguments do
      required(:database_id).filled(:string).description("The 32-hex-character database ID, optionally with dashes; a URL fragment works too")
    end

    def call(database_id:)
      notion_get("databases/#{normalize_id(database_id)}")
    end
  end
end
