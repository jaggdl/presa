# frozen_string_literal: true

module Seerr
  # Returns a paginated list of recommended TV shows based on a given show.
  class GetTvRecommendationsTool < Base
    description "List recommended TV shows based on a given show by TMDB ID"
    kind :get_tv_recommendations

    arguments do
      required(:tvId).filled(:integer).description("TMDB ID of the TV show")
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(tvId:, page: 1, language: nil)
      seerr_get("/tv/#{tvId}/recommendations", page: page, language: language)
    end
  end
end