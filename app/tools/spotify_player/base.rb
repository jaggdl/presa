# frozen_string_literal: true

module SpotifyPlayer
  # Abstract base for all Spotify Player tools. Not exposed directly. Shares
  # the Spotify request machinery (conn, OAuth token, 429 backoff) but binds
  # to the :spotify_player service kind and its narrower player scope. Reads
  # hit the Web Playback API; control commands send PUT/POST with a JSON body
  # as defined by the Spotify Web API reference.
  class Base < Spotify::Base
    service_kind :spotify_player
    abstract_tool true
  end
end
