# frozen_string_literal: true

module Oauth
  # Notion OAuth provider endpoints and brand icon, composed by the Notion
  # service and Notion OAuth client credentials. Unlike Google/Spotify/Strava,
  # Notion's consent flow carries no scope: the user picks which workspace the
  # integration is let into, and the issued integration token never expires.
  class Notion < Base
    key :notion
    icon "notion.png"
    authorize_uri "https://api.notion.com/v1/oauth/authorize"
    token_uri "https://api.notion.com/v1/oauth/token"
  end
end
