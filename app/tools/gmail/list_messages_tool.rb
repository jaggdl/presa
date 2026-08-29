# frozen_string_literal: true

module Gmail
  # Lists messages in the connected mailbox's inbox.
  class ListMessagesTool < Base
    description "List messages in the connected Gmail mailbox"

    arguments do
      optional(:query).filled(:string).description("Gmail search query, e.g. from:example@gmail.com is:unread")
      optional(:limit).filled(:integer, gt?: 0, lteq?: 100).description("Maximum number of messages to return (default 20)")
    end

    def call(query: nil, limit: nil)
      params = { maxResults: limit || 20 }
      params[:q] = query if query.present?
      gmail_get("users/me/messages", params: params)
    end
  end
end
