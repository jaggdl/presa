# frozen_string_literal: true

module Spotify
  # A single artist identified by their Spotify ID.
  class GetArtistTool < Base
    description "Get an artist by their Spotify ID"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the artist")
    end

    def call(id:)
      spotify_get("artists/#{id}")
    end
  end
end
