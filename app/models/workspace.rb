class Workspace < ApplicationRecord
  belongs_to :user
  has_many :api_tokens, dependent: :destroy
  has_many :workspace_services, dependent: :destroy
  has_many :services, through: :workspace_services

  validates :name, presence: true
end
