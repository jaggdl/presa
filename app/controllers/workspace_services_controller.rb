class WorkspaceServicesController < ApplicationController
  before_action :set_workspace

  def create
    service = Current.user.services.find(params[:service_id])
    WorkspaceService.create!(workspace: @workspace, service: service)

    redirect_to workspace_path(@workspace), notice: "Service added."
  rescue ActiveRecord::RecordInvalid
    redirect_to workspace_path(@workspace), alert: "Could not add service."
  end

  def destroy
    join = @workspace.workspace_services.find_by(service_id: params[:id])
    join&.destroy!

    redirect_to workspace_path(@workspace), notice: "Service removed from workspace."
  end

  private

  def set_workspace
    @workspace = Current.user.workspaces.find(params[:workspace_id])
  end
end
