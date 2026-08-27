# frozen_string_literal: true

# A reusable OAuth *client* (the "app"/BYO credential) for a provider, e.g. a
# Google OAuth client (client_id + client_secret). Unlike a grant, a client is
# shareable: one provider app can back many users' consent flows. Sharing is
# deferred; for now a credential is simply attributed to its creator.
class OauthClientCredential < ApplicationRecord
  encrypts :client_secret

  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id, inverse_of: :oauth_client_credentials
  has_many :grants, class_name: "OauthGrant", dependent: :destroy

  validates :provider, presence: true
  validates :client_id, presence: true, uniqueness: { scope: :provider }
  validates :client_secret, presence: true

  # A safe, fixed-length placeholder in place of the real secret for display.
  def masked_secret
    "••••••••"
  end
end
