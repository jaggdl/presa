# frozen_string_literal: true

module Seerr
  # Creates a new issue for a media item.
  class CreateIssueTool < Base
    description "Create a new issue for a media item on Seerr"
    kind :create_issue

    arguments do
      required(:mediaId).filled(:integer).description("Media ID the issue relates to")
      required(:message).filled(:string).description("Message describing the issue")
      required(:issueType).filled(:integer).description("Issue type (1 = video, 2 = audio, 3 = subtitles, 4 = other)")
      optional(:userId).filled(:integer).description("User ID to report the issue on behalf of")
    end

    def call(issueType:, message:, mediaId:, userId: nil)
      service.post("/issue", body: {
        issueType: issueType,
        message: message,
        mediaId: mediaId,
        userId: userId
      }.compact)
    end
  end
end
