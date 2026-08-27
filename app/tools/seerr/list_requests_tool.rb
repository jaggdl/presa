# frozen_string_literal: true

module Seerr
  # Lists media requests submitted on the Seerr instance.
  class ListRequestsTool < Base
    description "List media requests on the Seerr instance"
    kind :list_requests

    arguments do
      optional(:take).filled(:integer).description("Number of requests to return (default 20)")
      optional(:skip).filled(:integer).description("Number of requests to skip for pagination")
      optional(:status).filled(:string).description("Filter by request status")
      optional(:sort).filled(:string).description("Sort order, e.g. added, modified")
    end

    def call(take: 20, skip: 0, status: nil, sort: nil)
      params = { take: take, skip: skip }
      params[:status] = status if status.present?
      params[:sort] = sort if sort.present?

      service.get(query_path("/request", params))
    end
  end
end