# frozen_string_literal: true

class AddOauthProviderToOpenapiKinds < ActiveRecord::Migration[8.0]
  def change
    # Optional override of the OAuth provider key for an OpenAPI kind. Nil
    # keeps the default (the kind's namespace, as a dynamic provider); a preset
    # may set e.g. "google" so a Google-API kind shares the well-known
    # provider's client credentials, consent URL, and icon.
    add_column :openapi_kinds, :oauth_provider, :string
  end
end