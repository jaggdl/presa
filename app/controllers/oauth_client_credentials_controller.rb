class OauthClientCredentialsController < ApplicationController
  # GET /oauth_client_credentials
  def index
    @credentials = Current.user.oauth_client_credentials.order(:provider, :name)
  end

  # GET /oauth_client_credentials/new?provider=google&return_to=...
  def new
    @credential = OauthClientCredential.new(provider: params[:provider] || "google")
    load_provider_form
  end

  # POST /oauth_client_credentials
  def create
    @credential = Current.user.oauth_client_credentials.new(credential_params)

    if @credential.save
      redirect_to params[:return_to].presence || oauth_client_credentials_path, notice: "OAuth app added."
    else
      load_provider_form
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @credential = Current.user.oauth_client_credentials.find(params[:id])
    @credential.destroy!
    redirect_to params[:return_to].presence || oauth_client_credentials_path, notice: "OAuth client removed."
  end

private

  def load_provider_form
    @oauth_providers = oauth_providers
    selected = @oauth_providers.find { |p| p[:provider].to_s == @credential.provider.to_s }
    @service_scope = selected&.fetch(:scope)
  end

  # Distinct OAuth providers among the offerable OAuth service leaves, each
  # with its grouped default scopes, e.g. { provider: :google, scope:
  # "https://...gmail.readonly ..." } and { provider: :strava, scope:
  # "activity:read_all,profile:read_all" }.
  def oauth_providers
    Service.kinds.filter_map { |kind| Service.class_for_kind(kind) }
      .select { |klass| klass.respond_to?(:oauth_provider) && klass.oauth_provider.present? }
      .map { |klass| { provider: klass.oauth_provider.to_sym, scope: klass.oauth_scope } }
      .uniq { |p| p[:provider] }
      .sort_by { |p| p[:provider].to_s }
  end

  def credential_params
    params.require(:oauth_client_credential).permit(:provider, :name, :client_id, :client_secret, :scopes)
  end
end
