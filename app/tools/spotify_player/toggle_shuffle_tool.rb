# frozen_string_literal: true

module SpotifyPlayer
  # Toggle shuffle on or off for the user's playback. Requires Spotify
  # Premium.
  class ToggleShuffleTool < Base
    description "Toggle shuffle on or off for the user's playback (Premium)"

    arguments do
      required(:state).filled(:bool).description("true shuffles the user's playback, false does not")
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(state:, device_id: nil)
      params = { state: state }
      params[:device_id] = device_id if device_id
      spotify_put("me/player/shuffle", params: params)
    end
  end
end
