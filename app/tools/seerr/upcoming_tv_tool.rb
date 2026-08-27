# frozen_string_literal: true

module Seerr
  # Lists upcoming TV show premieres available on the Seerr catalog.
  class UpcomingTvTool < Base
    description "List upcoming TV show premieres on Seerr"
    kind :upcoming_tv

    arguments do
      optional(:page).filled(:integer).description("Page of results (default 1)")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(page: 1, language: nil)
      seerr_get("/discover/tv/upcoming", page: page, language: language)
    end
  end
end