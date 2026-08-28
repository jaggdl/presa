# frozen_string_literal: true

module SpotifyPlayer
  # The object currently being played on the user's account.
  class GetCurrentlyPlayingTool < Base
    description "Get the object currently being played on the user's account"

    arguments do
      optional(:market).filled(:string).description("An ISO 3166-1 alpha-2 country code or 'from_token'; only content available in that market is returned")
      optional(:additional_types).array(:str?).description("A comma-separated list of item types the client supports besides track (e.g. episode)")
    end

    def call(market: nil, additional_types: nil)
      params = {}
      params[:market] = market if market
      params[:additional_types] = additional_types.join(",") if additional_types&.any?
      spotify_get("me/player/currently-playing", params: params)
    end
  end
end
