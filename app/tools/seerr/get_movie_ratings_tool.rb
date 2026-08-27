# frozen_string_literal: true

module Seerr
  # Returns the Rotten Tomatoes ratings for a given movie.
  class GetMovieRatingsTool < Base
    description "Get Rotten Tomatoes ratings for a movie by TMDB ID"
    kind :get_movie_ratings

    arguments do
      required(:movieId).filled(:integer).description("TMDB ID of the movie")
    end

    def call(movieId:)
      seerr_get("/movie/#{movieId}/ratings")
    end
  end
end
