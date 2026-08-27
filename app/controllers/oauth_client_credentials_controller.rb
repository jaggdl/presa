class OauthClientCredentialsController < ApplicationController
  # GET /oauth_client_credentials
  def index
    @credentials = Current.user.oauth_client_credentials.order(:provider, :name)
  end

  # GET /oauth_client_credentials/new?provider=google&return_to=...
  def new
    @credential = OauthClientCredential.new(provider: params[:provider] || "google")
    @service_scope = oauth_service_for_provider(&:oauth_scope)
  end

  # POST /oauth_client_credentials
  def create
    @credential = Current.user.oauth_client_credentials.new(credential_params)

    if @credential.save
      redirect_to params[:return_to].presence || oauth_client_credentials_path, notice: "OAuth app added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @credential = Current.user.oauth_client_credentials.find(params[:id])
    @credential.destroy!
    redirect_to params[:return_to].presence || oauth_client_credentials_path, notice: "OAuth client removed."
  end

  private

  # Maps a provider (e.g. "google", "strava") to its offerable OAuth service
  # leaf so the new-credential form can prefill a default scope. Nil when the
  # provider has no backing service yet.
  def oauth_service_for_provider
    Service.kinds.filter_map { |kind| Service.class_for_kind(kind) }
      .find { |klass| klass.respond_to?(:oauth_provider) && klass.oauth_provider.to_s == @credential.provider }
  end

  def credential_params
    params.require(:oauth_client_credential).permit(:provider, :name, :client_id, :client_secret, :scopes)
  end
end
