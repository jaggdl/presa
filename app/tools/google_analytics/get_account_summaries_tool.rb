# frozen_string_literal: true

module GoogleAnalytics
  # Retrieves information about the user's Google Analytics accounts and
  # properties.
  class GetAccountSummariesTool < Base
    description "Retrieve information about the Google Analytics accounts and properties accessible to the connected account"

    def call
      ga_get(ADMIN_API, "/v1beta/accountSummaries")
    end
  end
end
