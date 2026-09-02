class ApiTokensController < ApplicationController
  def create
    @had_no_clients = workspace.api_tokens.none?
    @raw_token = ApiToken.issue!(workspace: workspace, name: api_token_params[:name].presence)
    @api_token = workspace.api_tokens.find_by(token_digest: ApiToken.digest(@raw_token))

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to workspace_path(workspace), flash: { token: @raw_token }, notice: "API token created. Copy it now — it won't be shown again." }
    end
  end

  def update
    api_token = workspace.api_tokens.find(params[:id])
    api_token.update(name: api_token_params[:name].presence)

    redirect_to workspace_path(workspace), notice: "Client name updated."
  end

  def destroy
    api_token = workspace.api_tokens.find(params[:id])
    api_token.revoke!

    redirect_to workspace_path(workspace), notice: "API token revoked."
  end

  private

  def workspace
    @workspace ||= Current.team.workspaces.find(params[:workspace_id])
  end

  def api_token_params
    params.require(:api_token).permit(:name)
  end
end
