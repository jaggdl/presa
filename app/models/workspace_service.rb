class WorkspaceService < ApplicationRecord
  belongs_to :workspace
  belongs_to :service

  validate :service_belongs_to_same_user

  private

  def service_belongs_to_same_user
    errors.add(:service, "must belong to the same user as the workspace") if workspace.user_id != service.user_id
  end
end
