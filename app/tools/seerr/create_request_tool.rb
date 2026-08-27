# frozen_string_literal: true

require "json"

module Seerr
  # Creates a new media request (movie or TV) on the Seerr instance.
  class CreateRequestTool < Base
    description "Create a new movie or TV request on Seerr"
    kind :create_request

    arguments do
      required(:mediaType).filled(:string).description("Media type: 'movie' or 'tv'")
      required(:mediaId).filled(:integer).description("TMDB ID of the movie or TV show to request")
      optional(:tvdbId).filled(:integer).description("TVDB ID (usually only set for TV requests)")
      optional(:seasons).filled(:string).description("TV seasons to request: 'all' or a JSON array of season numbers, e.g. \"[1,2]\"")
      optional(:is4k).filled(:bool).description("Request the 4K version (default false)")
      optional(:serverId).filled(:integer).description("Server ID to request from")
      optional(:profileId).filled(:integer).description("Quality profile ID to use")
      optional(:rootFolder).filled(:string).description("Root folder path to use")
      optional(:languageProfileId).filled(:integer).description("Language profile ID (Sonarr)")
      optional(:userId).filled(:integer).description("User ID to request on behalf of")
      optional(:ignoreQuota).filled(:bool).description("Ignore the requester's quota (requires MANAGE_REQUESTS permission)")
    end

    def call(mediaType:, mediaId:, tvdbId: nil, seasons: nil, is4k: nil, serverId: nil,
             profileId: nil, rootFolder: nil, languageProfileId: nil, userId: nil, ignoreQuota: nil)
      service.post("/request", body: {
        mediaType: mediaType,
        mediaId: mediaId,
        tvdbId: tvdbId,
        seasons: normalize_seasons(seasons),
        is4k: is4k,
        serverId: serverId,
        profileId: profileId,
        rootFolder: rootFolder,
        languageProfileId: languageProfileId,
        userId: userId,
        ignoreQuota: ignoreQuota
      }.compact)
    end

    private

    # The API accepts "all" or an array of season numbers. Pass numbers through
    # as a real array when a JSON array is given, otherwise keep the string.
    def normalize_seasons(seasons)
      return nil if seasons.nil? || seasons == "all"

      JSON.parse(seasons)
    rescue JSON::ParserError
      seasons
    end
  end
end
