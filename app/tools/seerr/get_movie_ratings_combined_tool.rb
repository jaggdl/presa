# frozen_string_literal: true

module Seerr
  # Returns the Rotten Tomatoes and IMDB ratings combined for a given movie.
  class GetMovieRatingsCombinedTool < Base
    description "Get RT and IMDB ratings combined for a movie by TMDB ID"
    kind :get_movie_ratings_combined

    arguments do
      required(:movieId).filled(:integer).description("TMDB ID of the movie")
    end

    def call(movieId:)
      seerr_get("/movie/#{movieId}/ratingscombined")
    end
  end
end
