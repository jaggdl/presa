# frozen_string_literal: true

module SpotifyPlayer
  # Seeks to a given position in the user's currently playing track. Requires
  # Spotify Premium.
  class SeekToPositionTool < Base
    description "Seek to a given position in the user's currently playing track (Premium)"

    arguments do
      required(:position_ms).filled(:integer, gteq?: 0).description("The position in milliseconds to seek to (must be positive)")
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(position_ms:, device_id: nil)
      params = { position_ms: position_ms }
      params[:device_id] = device_id if device_id
      spotify_put("me/player/seek", params: params)
    end
  end
end
