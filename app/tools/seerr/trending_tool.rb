# frozen_string_literal: true

module Seerr
  # Returns trending movies and TV shows on the Seerr catalog.
  class TrendingTool < Base
    description "Get trending movies and/or TV shows on Seerr"
    kind :trending

    arguments do
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
      optional(:mediaType).filled(:string).description("Media type to return: all, movie, or tv (default all)")
      optional(:timeWindow).filled(:string).description("Trending window: day or week (default day)")
    end

    def call(page: 1, language: nil, mediaType: nil, timeWindow: nil)
      seerr_get("/discover/trending",
                page: page, language: language, mediaType: mediaType, timeWindow: timeWindow)
    end
  end
end