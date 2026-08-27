# frozen_string_literal: true

module Seerr
  # Searches the Seerr catalog for TMDB keywords.
  class SearchKeywordTool < Base
    description "Search Seerr for TMDB keywords matching a query"
    kind :search_keyword

    arguments do
      required(:query).filled(:string).description("Keyword to search for, e.g. christmas")
      optional(:page).filled(:integer).description("Page of results (default 1)")
    end

    def call(query:, page: 1)
      seerr_get("/search/keyword", query: query, page: page)
    end
  end
end