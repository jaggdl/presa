class WorkspaceServicesController < ApplicationController
  before_action :set_workspace

  def create
    service = Current.user.services.find(params[:service_id])
    WorkspaceService.create!(workspace: @workspace, service: service)

    redirect_to workspace_path(@workspace), notice: "Service added."
  rescue ActiveRecord::RecordInvalid
    redirect_to workspace_path(@workspace), alert: "Could not add service."
  end

  def show
    @workspace_service = @workspace.workspace_services.includes(:service).find(params[:id])
    @tools = ApplicationTool.expose_for(@workspace_service.service)
  end

  def update
    @workspace_service = @workspace.workspace_services.includes(:service).find(params[:id])
    selected = Array(params.dig(:workspace_service, :allowed_tools)).reject(&:blank?)

    # Normalize "everything selected" into the "*" sentinel so tools added to
    # the service later remain allowed by default.
    available = @tools_for_update ||= ApplicationTool.expose_for(@workspace_service.service).map { |t| tool_key(t) }
    selected = [ WorkspaceService::ALLOW_ALL ] if available.present? && (selected - available).empty? && selected.length == available.length

    @workspace_service.allowed_tools = selected

    if @workspace_service.save
      redirect_to workspace_workspace_service_path(@workspace, @workspace_service), notice: "Allowed tools updated."
    else
      render :show, status: :unprocessable_entity
    end
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

  # Stable identifier used to choose an allowed tool: the remote tool name for
  # proxied MCP tools, otherwise the tool's kind (e.g. "search_user_media").
  def tool_key(bound_tool)
    bound_tool.tool_key
  end
end
