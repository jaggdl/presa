# frozen_string_literal: true

module SpotifyPlayer
  # Set the repeat mode for the user's playback. Requires Spotify Premium.
  class SetRepeatModeTool < Base
    description "Set the repeat mode for the user's playback: track, context, or off (Premium)"

    arguments do
      required(:state).filled(:string, included_in?: %w[track context off]).description("track repeats the current track, context repeats the current context, off turns repeat off")
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(state:, device_id: nil)
      params = { state: state }
      params[:device_id] = device_id if device_id
      spotify_put("me/player/repeat", params: params)
    end
  end
end
