# frozen_string_literal: true

module Seerr
  # Returns a single Seerr user by their Jellyfin user ID (the ID used by the
  # Jellyfin server, not Seerr).
  class GetUserByJellyfinIdTool < Base
    description "Get a Seerr user by their Jellyfin user ID"
    kind :get_user_by_jellyfin_id

    arguments do
      required(:jellyfinUserId).filled(:string).description("Jellyfin user ID of the user to fetch")
    end

    def call(jellyfinUserId:)
      seerr_get("/user/jellyfin/#{ERB::Util.url_encode(jellyfinUserId)}")
    end
  end
end
