# frozen_string_literal: true

module NanoBanana
  # Abstract base handler for all Nano Banana tools. Not exposed directly.
  class Base < ApplicationTool
    service_kind :nano_banana
    abstract_tool true
  end
end
