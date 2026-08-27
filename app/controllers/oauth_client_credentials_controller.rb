class OauthClientCredentialsController < ApplicationController
  # GET /oauth_client_credentials
  def index
    @credentials = Current.user.oauth_client_credentials.order(:provider, :name)
    @providers = oauth_providers
  end

  # GET /oauth_client_credentials/new?provider=google&return_to=...
  def new
    @credential = OauthClientCredential.new(provider: params[:provider] || "google")
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

  # GET /oauth_client_credentials/:id/edit
  def edit
    @credential = Current.user.oauth_client_credentials.find(params[:id])
  end

  # PATCH /oauth_client_credentials/:id
  def update
    @credential = Current.user.oauth_client_credentials.find(params[:id])

    # An empty client_secret field on update means "keep the stored secret".
    updates = credential_params
    updates = updates.except(:client_secret) if updates[:client_secret].blank?

    if @credential.update(updates)
      redirect_to params[:return_to].presence || oauth_client_credentials_path, notice: "OAuth client updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  # Distinct OAuth providers among the offerable OAuth service leaves, for the
  # credentials index tiles. Scopes are deliberately not surfaced here: each
  # service class declares the permissions its own consent requests.
  def oauth_providers
    Service.kinds.filter_map { |kind| Service.class_for_kind(kind) }
      .select { |klass| klass.respond_to?(:oauth_provider) && klass.oauth_provider.present? }
      .map { |klass| { provider: klass.oauth_provider.to_sym } }
      .uniq { |p| p[:provider] }
      .sort_by { |p| p[:provider].to_s }
  end

  def credential_params
    params.require(:oauth_client_credential).permit(:provider, :name, :client_id, :client_secret)
  end
end
