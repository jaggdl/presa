# frozen_string_literal: true

module SpotifyPlayer
  # The user's available Spotify Connect devices. Some device models are not
  # supported and are not listed.
  class GetAvailableDevicesTool < Base
    description "Get the user's available Spotify Connect devices"

    arguments { }

    def call
      spotify_get("me/player/devices")
    end
  end
end
