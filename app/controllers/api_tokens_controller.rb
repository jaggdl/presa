class ApiTokensController < ApplicationController
  def index
    @api_tokens = Current.user.api_tokens.order(created_at: :desc)
    @api_token = ApiToken.new
  end

  def create
    raw_token = ApiToken.issue!(user: Current.user, name: api_token_params[:name].presence)

    redirect_to root_path, flash: { token: raw_token }, notice: "API token created. Copy it now — it won't be shown again."
  end

  def destroy
    @api_token = Current.user.api_tokens.find(params[:id])
    @api_token.revoke!

    redirect_to root_path, notice: "API token revoked."
  end

  private

  def api_token_params
    params.require(:api_token).permit(:name)
  end
end
