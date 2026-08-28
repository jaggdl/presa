# frozen_string_literal: true

module Spotify
  # An artist's top tracks, based on the marketing country.
  class GetArtistTopTracksTool < Base
    description "Get an artist's top tracks by country"

    arguments do
      required(:id).filled(:string).description("The Spotify ID of the artist")
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code")
    end

    def call(id:, market: nil)
      params = {}
      params[:market] = market if market
      spotify_get("artists/#{id}/top-tracks", params: params)
    end
  end
end
