# frozen_string_literal: true

module Seerr
  # Returns the Rotten Tomatoes ratings for a given TV show.
  class GetTvRatingsTool < Base
    description "Get Rotten Tomatoes ratings for a TV show by TMDB ID"
    kind :get_tv_ratings

    arguments do
      required(:tvId).filled(:integer).description("TMDB ID of the TV show")
    end

    def call(tvId:)
      seerr_get("/tv/#{tvId}/ratings")
    end
  end
end