# frozen_string_literal: true

module Seerr
  # Returns watch data (play counts and users) for a media item.
  class GetMediaWatchDataTool < Base
    description "Get Seerr media watch data (play counts and watching users)"
    kind :get_media_watch_data

    arguments do
      required(:mediaId).filled(:integer).description("ID of the media item to fetch watch data for")
    end

    def call(mediaId:)
      seerr_get("/media/#{mediaId}/watch_data")
    end
  end
end