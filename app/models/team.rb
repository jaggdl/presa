class Team < ApplicationRecord
  # Whether this installation runs multi-tenant, i.e. any visitor may sign up
  # and provision their own team. Read from the MULTI_TENANT env var at boot.
  cattr_accessor :multi_tenant, default: false

  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships

  has_many :services, dependent: :destroy
  has_many :workspaces, dependent: :destroy
  has_many :oauth_client_credentials, dependent: :destroy

  validates :name, presence: true

  def member?(user)
    user.present? && users.exists?(id: user.id)
  end

  # Whether new signups are permitted at all: in a multi-tenant install always;
  # otherwise only during first run, while no users exist yet.
  def self.accepting_signups?
    multi_tenant || User.none?
  end

  # First run: a single-tenant install with no users yet. The app boots into a
  # setup flow so the first (and only) account can be created.
  def self.first_run?
    !multi_tenant && User.none?
  end
end
