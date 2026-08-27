# frozen_string_literal: true

module Seerr
  # Searches the Seerr catalog for TMDB production companies.
  class SearchCompanyTool < Base
    description "Search Seerr for TMDB companies (e.g. studios) matching a query"
    kind :search_company

    arguments do
      required(:query).filled(:string).description("Company name to search for, e.g. Disney")
      optional(:page).filled(:integer).description("Page of results (default 1)")
    end

    def call(query:, page: 1)
      seerr_get("/search/company", query: query, page: page)
    end
  end
end