# frozen_string_literal: true

module Gmail
  # Fetches a single message (without attachments) from the connected mailbox.
  class GetMessageTool < Base
    description "Fetch a single message (id and metadata) from the connected Gmail mailbox"

    arguments do
      required(:id).filled(:string).description("The message id to fetch, as returned by list_messages")
    end

    def call(id:)
      gmail_get("/gmail/v1/users/me/messages/#{id}")
    end
  end
end
