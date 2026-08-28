class Team < ApplicationRecord
  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships

  has_many :services, dependent: :destroy
  has_many :workspaces, dependent: :destroy
  has_many :oauth_client_credentials, dependent: :destroy

  validates :name, presence: true

  def member?(user)
    user.present? && users.exists?(id: user.id)
  end
end
