# frozen_string_literal: true

module Oauth
  # Spotify OAuth provider endpoints and brand icon, composed by the Spotify
  # service and Spotify OAuth client credentials.
  class Spotify < Base
    key :spotify
    icon "spotify.png"
    authorize_uri "https://accounts.spotify.com/authorize"
    token_uri "https://accounts.spotify.com/api/token"
  end
end
