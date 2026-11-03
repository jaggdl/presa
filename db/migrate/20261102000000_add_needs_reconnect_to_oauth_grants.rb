# frozen_string_literal: true

# Marks a grant whose refresh token the provider has rejected (expired or
# revoked). Unlike a transient failure this cannot self-heal: the service must
# be reconnected by a human, so the flag lets the API and the UI report an
# explicit "needs reconnect" state instead of retrying a doomed refresh or
# leaking the provider's raw `invalid_grant` error.
class AddNeedsReconnectToOauthGrants < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_grants, :needs_reconnect, :boolean, default: false, null: false
    add_column :oauth_grants, :needs_reconnect_at, :datetime
  end
end
