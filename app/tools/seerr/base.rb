# frozen_string_literal: true

module Seerr
  # Abstract base handler for all Seerr tools. Not exposed directly.
  class Base < ApplicationTool
    service_kind :seerr
    abstract_tool true

    private

    # Append query params to a path, URL-encoded, e.g. "/search" with
    # { query: "dune", page: 2 } => "/search?query=dune&page=2".
    def query_path(path, params)
      return path if params.blank?

      query = params.map { |k, v| "#{ERB::Util.url_encode(k)}=#{ERB::Util.url_encode(v)}" }.join("&")
      "#{path}?#{query}"
    end
  end
end