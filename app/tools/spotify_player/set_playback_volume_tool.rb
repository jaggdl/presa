# frozen_string_literal: true

module SpotifyPlayer
  # Set the volume for the user's current playback device. Requires Spotify
  # Premium.
  class SetPlaybackVolumeTool < Base
    description "Set the volume for the user's current playback device, from 0 to 100 (Premium)"

    arguments do
      required(:volume_percent).filled(:integer, gteq?: 0, lteq?: 100).description("The volume to set, from 0 to 100 inclusive")
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(volume_percent:, device_id: nil)
      params = { volume_percent: volume_percent }
      params[:device_id] = device_id if device_id
      spotify_put("me/player/volume", params: params)
    end
  end
end
