# frozen_string_literal: true

# A reusable OAuth *client* (the "app"/BYO credential) for a provider, e.g. a
# Google OAuth client (client_id + client_secret). Unlike a grant, a client is
# shareable: one provider app can back many users' consent flows. A credential
# is owned by a team and shared across that team's members.
class OauthClientCredential < ApplicationRecord
  encrypts :client_secret

  belongs_to :team
  has_many :grants, class_name: "OauthGrant", dependent: :destroy

  validates :provider, presence: true
  validates :name, presence: true
  validates :client_id, presence: true, uniqueness: { scope: :provider }
  validates :client_secret, presence: true

  # The brand image filename for this credential's provider, resolved from the
  # provider class (Oauth::Google, Oauth::Spotify, ...), or the generic
  # placeholder when the provider is unknown.
  def self.icon_for(provider)
    Oauth::Base.for_provider(provider)&.icon || "placeholder.png"
  end

  # A safe, fixed-length placeholder in place of the real secret for display.
  def masked_secret
    "••••••••"
  end
end
