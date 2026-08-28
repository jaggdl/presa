# frozen_string_literal: true

module Services
  # Spotify, backed by Spotify's own OAuth2 Authorization Code flow (per-service
  # BYO client). The user adds a Spotify app's client credentials and
  # authorizes their account; the service then exposes Spotify tools (profile,
  # top items, saved tracks, playlists) carrying the acquired grant's token.
  # Endpoints and scope follow the Spotify Web API reference at
  # https://developer.spotify.com/documentation/web-api.
  class Spotify < OauthService
    kind :spotify
    icon "spotify.png"
    category :media

    # The minimum scope covering the features this integration exposes:
    # profile, top items, recently played, saved tracks, and playlists.
    self.oauth_provider = :spotify
    self.oauth_scope = "user-read-private user-top-read user-read-recently-played user-library-read playlist-read-private"
  end
end
