class OauthClientCredentialsController < ApplicationController
  # GET /oauth_client_credentials/new?provider=google&return_to=...
  def new
    @credential = OauthClientCredential.new(provider: params[:provider] || "google")
    @service_scope = Services::Gmail.oauth_scope
  end

  # POST /oauth_client_credentials
  def create
    @credential = Current.user.oauth_client_credentials.new(credential_params)

    if @credential.save
      redirect_to params[:return_to].presence || services_path, notice: "OAuth app added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @credential = Current.user.oauth_client_credentials.find(params[:id])
    @credential.destroy!
    redirect_to params[:return_to].presence || services_path, notice: "OAuth client removed."
  end

  private

  def credential_params
    params.require(:oauth_client_credential).permit(:provider, :client_id, :client_secret, :scopes)
  end
end
