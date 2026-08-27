# frozen_string_literal: true

module Seerr
  # Discovers movies on the Seerr catalog with optional filters.
  class DiscoverMoviesTool < Base
    description "Discover movies on Seerr, filterable by genre, studio, language, and more"
    kind :discover_movies

    arguments do
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
      optional(:genre).filled(:string).description("Genre ID to filter by, e.g. 18")
      optional(:studio).filled(:integer).description("Studio/company ID to filter by")
      optional(:keywords).filled(:string).description("Comma-separated keyword IDs to include, e.g. 1,2")
      optional(:excludeKeywords).filled(:string).description("Comma-separated keyword IDs to exclude, e.g. 3,4")
      optional(:sortBy).filled(:string).description("Sort order, e.g. popularity.desc")
      optional(:primaryReleaseDateGte).filled(:string).description("Earliest release date (YYYY-MM-DD)")
      optional(:primaryReleaseDateLte).filled(:string).description("Latest release date (YYYY-MM-DD)")
      optional(:withRuntimeGte).filled(:integer).description("Minimum runtime in minutes")
      optional(:withRuntimeLte).filled(:integer).description("Maximum runtime in minutes")
      optional(:voteAverageGte).filled(:integer).description("Minimum vote average (0-10)")
      optional(:voteCountGte).filled(:integer).description("Minimum vote count")
      optional(:watchProviders).filled(:string).description("Watch provider IDs, e.g. 8|9")
    end

    def call(page: 1, language: nil, genre: nil, studio: nil, keywords: nil,
             excludeKeywords: nil, sortBy: nil, primaryReleaseDateGte: nil,
             primaryReleaseDateLte: nil, withRuntimeGte: nil, withRuntimeLte: nil,
             voteAverageGte: nil, voteCountGte: nil, watchProviders: nil)
      seerr_get("/discover/movies",
                page: page, language: language, genre: genre, studio: studio,
                keywords: keywords, excludeKeywords: excludeKeywords, sortBy: sortBy,
                primaryReleaseDateGte: primaryReleaseDateGte, primaryReleaseDateLte: primaryReleaseDateLte,
                withRuntimeGte: withRuntimeGte, withRuntimeLte: withRuntimeLte,
                voteAverageGte: voteAverageGte, voteCountGte: voteCountGte, watchProviders: watchProviders)
    end
  end
end
