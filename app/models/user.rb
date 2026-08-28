class User < ApplicationRecord
  include Authenticatable
  has_many :sessions, dependent: :destroy
  has_many :workspaces, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :oauth_client_credentials, dependent: :destroy, inverse_of: :created_by
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships

  after_create :ensure_default_team

  def can_use_tool?(_tool)
    true
  end

  private

  def ensure_default_team
    teams.create!(name: "#{email_address}'s team")
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
