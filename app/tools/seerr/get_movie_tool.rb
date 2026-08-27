# frozen_string_literal: true

module Seerr
  # Returns full details for a single movie on the Seerr catalog.
  class GetMovieTool < Base
    description "Get details for a single movie by TMDB ID"
    kind :get_movie

    arguments do
      required(:movieId).filled(:integer).description("TMDB ID of the movie")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(movieId:, language: nil)
      seerr_get("/movie/#{movieId}", language: language)
    end
  end
end