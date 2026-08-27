# frozen_string_literal: true

module Seerr
  # Returns a paginated list of movies similar to a given movie.
  class GetMovieSimilarTool < Base
    description "Get movies similar to a given movie by TMDB ID"
    kind :get_movie_similar

    arguments do
      required(:movieId).filled(:integer).description("TMDB ID of the movie")
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(movieId:, page: 1, language: nil)
      seerr_get("/movie/#{movieId}/similar", page: page, language: language)
    end
  end
end
