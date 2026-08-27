class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :workspaces, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :oauth_client_credentials, dependent: :destroy, inverse_of: :created_by

  def can_use_tool?(_tool)
    true
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
