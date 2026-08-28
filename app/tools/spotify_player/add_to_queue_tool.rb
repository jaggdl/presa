# frozen_string_literal: true

module SpotifyPlayer
  # Add an item to be played next in the user's current playback queue.
  # Requires Spotify Premium.
  class AddToQueueTool < Base
    description "Add an item to be played next in the user's current playback queue (Premium)"

    arguments do
      required(:uri).filled(:string).description("The Spotify URI of the item to add (a track or episode uri)")
      optional(:device_id).filled(:string).description("The id of the device this command is targeting; the user's currently active device if not supplied")
    end

    def call(uri:, device_id: nil)
      params = { uri: uri }
      params[:device_id] = device_id if device_id
      spotify_post("me/player/queue", params: params)
    end
  end
end
