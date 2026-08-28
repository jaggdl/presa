# frozen_string_literal: true

module Spotify
  # Artists related to a given artist.
  class GetArtistRelatedArtistsTool < Base
    description "Get Spotify catalog information about artists similar to a given artist"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the artist")
    end

    def call(id:)
      spotify_get("artists/#{id}/related-artists")
    end
  end
end
