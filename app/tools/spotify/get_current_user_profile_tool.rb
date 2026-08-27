# frozen_string_literal: true

module Spotify
  # Fetches the current user's Spotify profile (public + account details the
  # user-read-private scope grants).
  class GetCurrentUserProfileTool < Base
    description "Get detailed profile information about the current Spotify user"
    kind "get_current_user_profile"

    def call
      spotify_get("me")
    end
  end
end
