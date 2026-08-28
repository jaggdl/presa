class TeamMembership < ApplicationRecord
  enum :role, {
    owner: 0,
    member: 1
  }, default: :owner

  belongs_to :team
  belongs_to :user
end
