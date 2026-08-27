# frozen_string_literal: true

module Seerr
  # Discovers TV shows on the Seerr catalog with optional filters.
  class DiscoverTvTool < Base
    description "Discover TV shows on Seerr, filterable by genre, network, language, and more"
    kind :discover_tv

    arguments do
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
      optional(:genre).filled(:string).description("Genre ID to filter by, e.g. 18")
      optional(:network).filled(:integer).description("Network ID to filter by")
      optional(:keywords).filled(:string).description("Comma-separated keyword IDs to include, e.g. 1,2")
      optional(:excludeKeywords).filled(:string).description("Comma-separated keyword IDs to exclude, e.g. 3,4")
      optional(:sortBy).filled(:string).description("Sort order, e.g. popularity.desc")
      optional(:firstAirDateGte).filled(:string).description("Earliest first air date (YYYY-MM-DD)")
      optional(:firstAirDateLte).filled(:string).description("Latest first air date (YYYY-MM-DD)")
      optional(:withRuntimeGte).filled(:integer).description("Minimum runtime in minutes")
      optional(:withRuntimeLte).filled(:integer).description("Maximum runtime in minutes")
      optional(:voteAverageGte).filled(:integer).description("Minimum vote average (0-10)")
      optional(:voteCountGte).filled(:integer).description("Minimum vote count")
      optional(:watchProviders).filled(:string).description("Watch provider IDs, e.g. 8|9")
    end

    def call(page: 1, language: nil, genre: nil, network: nil, keywords: nil,
             excludeKeywords: nil, sortBy: nil, firstAirDateGte: nil,
             firstAirDateLte: nil, withRuntimeGte: nil, withRuntimeLte: nil,
             voteAverageGte: nil, voteCountGte: nil, watchProviders: nil)
      seerr_get("/discover/tv",
                page: page, language: language, genre: genre, network: network,
                keywords: keywords, excludeKeywords: excludeKeywords, sortBy: sortBy,
                firstAirDateGte: firstAirDateGte, firstAirDateLte: firstAirDateLte,
                withRuntimeGte: withRuntimeGte, withRuntimeLte: withRuntimeLte,
                voteAverageGte: voteAverageGte, voteCountGte: voteCountGte, watchProviders: watchProviders)
    end
  end
end