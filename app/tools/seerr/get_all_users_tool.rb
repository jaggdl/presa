# frozen_string_literal: true

module Seerr
  # Returns all users on the Seerr instance, as seen by the calling user.
  class GetAllUsersTool < Base
    description "Get all users on the Seerr instance"
    kind :get_all_users

    def call
      seerr_get("/user")
    end
  end
end
