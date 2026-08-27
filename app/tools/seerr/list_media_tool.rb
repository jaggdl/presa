# frozen_string_literal: true

module Seerr
  # Lists all media tracked by the Seerr instance, with optional filtering.
  class ListMediaTool < Base
    description "Get media from Seerr (filtered and limited)"
    kind :list_media

    arguments do
      optional(:take).filled(:integer).description("Number of media items to return (default 20)")
      optional(:skip).filled(:integer).description("Number of media items to skip for pagination")
      optional(:filter).filled(:string).description("Filter by status: all, available, partial, allavailable, processing, pending, deleted")
      optional(:sort).filled(:string).description("Sort order: added, modified, mediaAdded (default added)")
    end

    def call(take: nil, skip: nil, filter: nil, sort: nil)
      seerr_get("/media", take: take, skip: skip, filter: filter, sort: sort)
    end
  end
end