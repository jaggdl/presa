# frozen_string_literal: true

module Spotify
  # Audio features for multiple tracks based on their Spotify IDs.
  class GetSeveralTracksAudioFeaturesTool < Base
    description "Get audio features for multiple tracks based on their Spotify IDs"

    arguments do
      required(:ids).array(:str?).description("A comma-separated list of the Spotify IDs for the tracks. Maximum: 100 IDs.")
    end

    def call(ids:)
      spotify_get("audio-features", params: { ids: ids.join(",") })
    end
  end
end
