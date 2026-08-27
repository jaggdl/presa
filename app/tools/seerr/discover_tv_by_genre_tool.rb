# frozen_string_literal: true

module Seerr
  # Discovers TV shows on the Seerr catalog by TMDB genre ID.
  class DiscoverTvByGenreTool < Base
    description "Discover TV shows on Seerr for a given TMDB genre ID"
    kind :discover_tv_by_genre

    arguments do
      required(:genreId).filled(:string).description("TMDB genre ID, e.g. 10765 for Sci-Fi & Fantasy")
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(genreId:, page: 1, language: nil)
      seerr_get("/discover/tv/genre/#{genreId}", page: page, language: language)
    end
  end
end