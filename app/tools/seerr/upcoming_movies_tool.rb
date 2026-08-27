# frozen_string_literal: true

module Seerr
  # Lists upcoming theatrical releases available on the Seerr catalog.
  class UpcomingMoviesTool < Base
    description "List upcoming movie releases on Seerr"
    kind :upcoming_movies

    arguments do
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(page: 1, language: nil)
      seerr_get("/discover/movies/upcoming", page: page, language: language)
    end
  end
end