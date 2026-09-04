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

      # Optional OAuth provider key override for kinds whose spec declares an
      # OAuth scheme. Defaults to the namespace (a kind-local dynamic provider);
      # set e.g. `google` so a Google-API kind shares the well-known provider's
      # client credentials and icon instead of minting its own.
      def oauth_provider
        data["oauth_provider"].to_s.presence
      end

      # Optional credential-transmission override for specs whose declared
      # scheme is wrong for the real server (e.g. Jellyfin's spec says
      # `Authorization` but the server wants `X-Emby-Token`). YAML shape:
      #
      #   credential:
      #     scheme: CustomAuthentication   # the security scheme to override
      #     in: header                     # header | query | cookie
      #     param_name: X-Emby-Token       # header/query/cookie name
      #
      # Applied at install by rewriting the scheme's slot in the definition.
      def credential_override
        cred = data["credential"]
        return nil unless cred.is_a?(Hash)

        scheme = cred["scheme"].to_s.presence
        return nil if scheme.blank?

        { "scheme" => scheme, "in" => cred["in"].to_s.presence || "header",
          "param_name" => cred["param_name"].to_s.presence }
      end
    end
  end
end
