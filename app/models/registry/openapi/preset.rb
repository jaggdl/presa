# frozen_string_literal: true

module Registry
  module Openapi
    # One OpenAPI preset: an entry in `registry/openapi/<namespace>.yml` that
    # seeds a reusable `OpenapiKind`. Adds the kind-seeding fields (spec URL,
    # default base URL, health-check operation) on top of the shared preset
    # fields (title, category, tags, description, icon).
    class Preset < Registry::Preset
      def self.directory
        Registry.root.join("openapi")
      end

      def spec_url
        data["spec_url"].to_s.presence
      end

      def base_url
        data["base_url"].to_s.presence
      end

      def health_op
        data["health_op"].to_s.presence
      end
    end
  end
end
