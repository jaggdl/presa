class Workspace < ApplicationRecord
  belongs_to :user
  has_many :api_tokens, dependent: :destroy

  validates :name, presence: true
end
