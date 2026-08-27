# frozen_string_literal: true

module Seerr
  # Returns full details for a single TV show on the Seerr catalog.
  class GetTvTool < Base
    description "Get details for a single TV show by TMDB ID"
    kind :get_tv

    arguments do
      required(:tvId).filled(:integer).description("TMDB ID of the TV show")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(tvId:, language: nil)
      seerr_get("/tv/#{tvId}", language: language)
    end
  end
end