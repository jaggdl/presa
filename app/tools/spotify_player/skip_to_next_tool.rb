# frozen_string_literal: true

module SpotifyPlayer
  # Skips to the next track in the user's queue. Requires Spotify Premium.
  class SkipToNextTool < Base
    description "Skip to the next track in the user's queue (Premium)"

    arguments do
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(device_id: nil)
      params = {}
      params[:device_id] = device_id if device_id
      spotify_post("me/player/next", params: params)
    end
  end
end
