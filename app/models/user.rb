class User < ApplicationRecord
  include Authenticatable
  has_many :sessions, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships

  # Resources are owned by teams, not users: a user sees everything their teams
  # own through the memberships above.
  has_many :services, through: :teams
  has_many :workspaces, through: :teams
  has_many :oauth_client_credentials, through: :teams

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
