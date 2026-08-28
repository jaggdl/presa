# frozen_string_literal: true

module SpotifyPlayer
  # Pause playback on the user's account. Requires Spotify Premium.
  class PausePlaybackTool < Base
    description "Pause playback on the user's account (Premium)"

    arguments do
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(device_id: nil)
      params = {}
      params[:device_id] = device_id if device_id
      spotify_put("me/player/pause", params: params)
    end
  end
end
