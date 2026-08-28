# frozen_string_literal: true

module SpotifyPlayer
  # The list of objects that make up the user's playback queue.
  class GetUserQueueTool < Base
    description "Get the list of objects that make up the user's playback queue"

    arguments { }

    def call
      spotify_get("me/player/queue")
    end
  end
end
