# frozen_string_literal: true

module Spotify
  # The available genre seed values accepted by the recommendations endpoint.
  class GetAvailableGenreSeedsTool < Base
    description "Retrieve a list of available genre seed parameter values for recommendations"

    def call
      spotify_get("recommendations/available-genre-seeds")
    end
  end
end
