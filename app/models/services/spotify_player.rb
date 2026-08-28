# frozen_string_literal: true

module Services
  # Spotify Player, a sibling of Spotify that exposes a connected account's
  # Web Playback controls. Sat on top of the same Spotify OAuth2 client as the
  # Spotify service (per-service BYO client), but requesting the narrower
  # player scope so a grant granted here can drive and read a user's active
  # device. Exposes read (playback state, available devices, currently playing,
  # queue) and control (play/pause, skip, seek, volume, shuffle, repeat,
  # transfer, add-to-queue) tools carrying the acquired grant's token.
  class SpotifyPlayer < ::OauthService
    kind :spotify_player
    icon "spotify.png"
    category :media

    # The minimum scope covering the player endpoints this service exposes.
    # Player read commands need the two read scopes; every control command
    # (start/pause/skip/seek/volume/shuffle/repeat/transfer/add-to-queue) needs
    # user-modify-playback-state. Endpoints follow the Spotify Web API
    # reference.
    self.oauth_provider = :spotify
    self.oauth_scope = "user-read-playback-state user-read-currently-playing user-modify-playback-state"
  end
end
