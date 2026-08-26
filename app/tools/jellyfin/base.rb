module Tools
  module Jellyfin
    # Abstract base handler for all Jellyfin tools. Not exposed directly.
    class Base < ApplicationTool
      service_kind :jellyfin
      abstract_tool true

      private

      # Resolve a user id for user-scoped endpoints. Falls back to the first
      # server user when one isn't supplied by the caller.
      def resolve_user_id(provided)
        return provided if provided.present?

        users = service.get("/Users")
        users.is_a?(Array) && users.first ? users.first["Id"] : nil
      end

      def media_url(path, params)
        query = params.map { |k, v| "#{k}=#{ERB::Util.url_encode(v)}" }.join("&")
        "#{path}?#{query}"
      end
    end
  end
end
