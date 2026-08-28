# frozen_string_literal: true

module Spotify
  # A low-level audio analysis for a track, covering its rhythm, pitch and
  # timbre, by Spotify ID.
  class GetTrackAudioAnalysisTool < Base
    description "Get a low-level audio analysis for a track in the Spotify catalog"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the track")
    end

    def call(id:)
      spotify_get("audio-analysis/#{id}")
    end
  end
end
