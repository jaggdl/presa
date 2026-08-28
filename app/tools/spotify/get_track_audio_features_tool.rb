# frozen_string_literal: true

module Spotify
  # Audio feature information for a single track by its Spotify ID.
  class GetTrackAudioFeaturesTool < Base
    description "Get audio feature information for a single track"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the track")
    end

    def call(id:)
      spotify_get("audio-features/#{id}")
    end
  end
end
