# frozen_string_literal: true

module Seerr
  # Updates a media item's status (available, partial, processing, etc).
  class UpdateMediaStatusTool < Base
    description "Update a media item's available status on Seerr"
    kind :update_media_status

    arguments do
      required(:mediaId).filled(:integer).description("ID of the media item to update")
      required(:status).filled(:string).description("New status: available, partial, processing, pending, unknown, deleted")
      optional(:is4k).filled(:bool).description("When true, update the 4K status field (status4k) instead of the regular one")
    end

    def call(mediaId:, status:, is4k: nil)
      service.post("/media/#{mediaId}/#{status}", body: { is4k: is4k }.compact)
    end
  end
end