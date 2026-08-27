# frozen_string_literal: true

module Seerr
  # Searches for movies, TV shows, or people on the Seerr catalog.
  class SearchTool < Base
    description "Search Seerr for movies, TV shows, or people"
    kind :search

    arguments do
      required(:query).filled(:string).description("Search term to match against movies, TV shows, and people")
      optional(:page).filled(:integer).description("Page of results (default 1)")
    end

    def call(query:, page: 1)
      seerr_get("/search", query: query, page: page)
    end
  end
end