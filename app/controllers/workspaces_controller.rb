class WorkspacesController < ApplicationController
  before_action :set_workspace, only: %i[ show edit update invocations ]

  def index
    @workspaces = Workspace.with_invocation_counts(
      Current.user.workspaces.includes(:api_tokens, services: {}).order(:created_at)
    )
  end

  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Current.user.workspaces.build(workspace_params)

    if @workspace.save
      redirect_to workspace_path(@workspace), notice: "Workspace created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workspace.update(workspace_params)
      redirect_to workspace_path(@workspace), notice: "Workspace updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @api_tokens = ApiToken.with_invocation_counts(@workspace.api_tokens.order(created_at: :desc))
    @api_token = ApiToken.new
    @linked_services = Service.with_invocation_counts(@workspace.services.order(:type, :name))
    @available_services = Current.user.services.where.not(id: @linked_services.pluck(:id)).order(:type, :name)
    @tool_invocations = ToolInvocation.for_workspace(@workspace).recent(10).includes(:service, :api_token)
  end

  # Lazy-loads older invocations, appending them to the live log via turbo streams.
  def invocations
    relation = ToolInvocation.for_workspace(@workspace)
    relation = relation.where("tool_invocations.id < ?", params[:before_id]) if params[:before_id].present?
    @tool_invocations = relation.order(id: :desc).limit(10).includes(:service, :api_token)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to workspace_path(@workspace) }
    end
  end

  private

  def set_workspace
    @workspace = Current.user.workspaces.find(params[:id])
  end

  def workspace_params
    params.require(:workspace).permit(:name)
  end
end
