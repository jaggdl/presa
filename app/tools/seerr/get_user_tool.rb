# frozen_string_literal: true

module Seerr
  # Returns a single Seerr user by their internal user ID. Requires the
  # MANAGE_USERS permission on the Seerr instance.
  class GetUserTool < Base
    description "Get a Seerr user by their Seerr user ID"
    kind :get_user

    arguments do
      required(:userId).filled(:integer).description("Seerr user ID of the user to fetch")
    end

    def call(userId:)
      seerr_get("/user/#{userId}")
    end
  end
end
