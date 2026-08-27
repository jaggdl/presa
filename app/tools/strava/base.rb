# frozen_string_literal: true

module Tools
  module Strava
    # Abstract base handler for all Strava tools. Not exposed directly.
    class Base < ApplicationTool
      service_kind :strava
      abstract_tool true
    end
  end
end