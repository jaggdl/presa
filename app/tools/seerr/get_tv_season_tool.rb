# frozen_string_literal: true

module Seerr
  # Returns season details and its episode list for a given TV show.
  class GetTvSeasonTool < Base
    description "Get a TV show's season details and episode list by TMDB ID"
    kind :get_tv_season

    arguments do
      required(:tvId).filled(:integer).description("TMDB ID of the TV show")
      required(:seasonNumber).filled(:integer).description("Season number to fetch details for")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(tvId:, seasonNumber:, language: nil)
      seerr_get("/tv/#{tvId}/season/#{seasonNumber}", language: language)
    end
  end
end
