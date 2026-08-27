# frozen_string_literal: true

module Seerr
  # Returns a person's combined cast and crew credits from TMDB.
  class GetPersonCreditsTool < Base
    description "Get a person's combined cast and crew credits from Seerr"
    kind :get_person_credits

    arguments do
      required(:personId).filled(:integer).description("TMDB ID of the person to fetch credits for")
      optional(:language).filled(:string).description("Language to localize results, e.g. en")
    end

    def call(personId:, language: nil)
      seerr_get("/person/#{personId}/combined_credits", language: language)
    end
  end
end
