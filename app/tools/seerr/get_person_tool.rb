# frozen_string_literal: true

module Seerr
  # Returns details for a person (e.g. an actor or director) by TMDB ID.
  class GetPersonTool < Base
    description "Get Seerr person details by TMDB ID"
    kind :get_person

    arguments do
      required(:personId).filled(:integer).description("TMDB ID of the person to fetch")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(personId:, language: nil)
      seerr_get("/person/#{personId}", language: language)
    end
  end
end
