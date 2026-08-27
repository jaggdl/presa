# frozen_string_literal: true

module Seerr
  # Returns a paginated list of TV shows similar to a given show.
  class GetTvSimilarTool < Base
    description "Get TV shows similar to a given show by TMDB ID"
    kind :get_tv_similar

    arguments do
      required(:tvId).filled(:integer).description("TMDB ID of the TV show")
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(tvId:, page: 1, language: nil)
      seerr_get("/tv/#{tvId}/similar", page: page, language: language)
    end
  end
end
