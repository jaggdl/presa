# frozen_string_literal: true

module Seerr
  # Discovers movies on the Seerr catalog by TMDB genre ID.
  class DiscoverMoviesByGenreTool < Base
    description "Discover movies on Seerr for a given TMDB genre ID"
    kind :discover_movies_by_genre

    arguments do
      required(:genreId).filled(:string).description("TMDB genre ID, e.g. 28 for Action")
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(genreId:, page: 1, language: nil)
      seerr_get("/discover/movies/genre/#{genreId}", page: page, language: language)
    end
  end
end
