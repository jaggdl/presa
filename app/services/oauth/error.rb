# frozen_string_literal: true

module Oauth
  # Raised on OAuth token/refresh failures that aren't a redirect-worthy prompt.
  # Own file so Zeitwerk can autoload it from anywhere (`Oauth::Exchange` is
  # loaded lazily, but the error class is raised by services and concerns that
  # reference it directly).
  class Error < StandardError; end
end
