# frozen_string_literal: true

module SpotifyPlayer
  # Transfer playback to a new device and optionally begin playback. Requires
  # Spotify Premium.
  class TransferPlaybackTool < Base
    description "Transfer playback to a new device and optionally begin playback (Premium)"

    arguments do
      required(:device_ids).array(:str?).description("The ID of the device on which playback should be started/transferred (only a single device is supported)")
      optional(:play).filled(:bool).description("true ensures playback happens on the new device; false or unset keeps the current playback state")
    end

    def call(device_ids:, play: nil)
      body = { device_ids: device_ids }
      body[:play] = play unless play.nil?
      spotify_put("me/player", body: body)
    end
  end
end
