# frozen_string_literal: true

module Seerr
  # Abstract base handler for all Seerr tools. Not exposed directly.
  class Base < ApplicationTool
    service_kind :seerr
    abstract_tool true

    private

    # Perform a GET against the Seerr API, URL-encoding the given query params
    # and dropping nil values. Tools pass clean paths (no /api/v1 prefix).
    #
    #   seerr_get("/discover/movies", page: 1, language: nil) => GET /discover/movies?page=1
    def seerr_get(path, params = {})
      service.get(query_path(path, compact_params(params)))
    end

    # Append query params to a path, URL-encoded, e.g. "/search" with
    # { query: "dune", page: 2 } => "/search?query=dune&page=2".
    def query_path(path, params)
      return path if params.blank?

      query = params.map { |k, v| "#{ERB::Util.url_encode(k)}=#{ERB::Util.url_encode(v)}" }.join("&")
      "#{path}?#{query}"
    end

    # Drop nil-valued entries so unset optional args don't become stray params.
    def compact_params(hash)
      hash.reject { |_k, v| v.nil? }
    end
  end
end
