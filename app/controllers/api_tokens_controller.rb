class ApiTokensController < ApplicationController
  def create
    raw_token = ApiToken.issue!(workspace: workspace, name: api_token_params[:name].presence)

    redirect_to workspace_path(workspace), flash: { token: raw_token }, notice: "API token created. Copy it now — it won't be shown again."
  end

  def destroy
    api_token = workspace.api_tokens.find(params[:id])
    api_token.revoke!

    redirect_to workspace_path(workspace), notice: "API token revoked."
  end

  private

  def workspace
    @workspace ||= Current.user.workspaces.find(params[:workspace_id])
  end

  def api_token_params
    params.require(:api_token).permit(:name)
  end
end
