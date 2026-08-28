class ServicesController < ApplicationController
  before_action :set_service, only: %i[ show edit update destroy ]

  def index
    @services = Service.with_invocation_counts(Current.user.services.order(:type, :name))
    # Available service kinds a user can add, MCP first then alphabetical.
    @kinds = Service.kinds.sort_by { |kind| [ kind == "mcp" ? 0 : 1, kind ] }
    # Prefetch remote tool lists in parallel so the per-row tool counts don't
    # trigger a serial MCP discovery round-trip per service.
    Services::Mcp.warm_remote_tools(@services)
  end

  def new
    klass = Service.class_for_kind(params[:kind]) || Service.class_for_kind(Service.kinds.first)
    @service = klass.new
    load_oauth_clients
  end

  def create
    if service_klass <= OauthService
      return create_oauth_service
    end

    @service = service_klass.new(user: Current.user, name: service_params[:name], config: service_config_params)

    if @service.save
      redirect_to services_path, notice: "Service created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tools = ApplicationTool.expose_for(@service)
  end

  def edit
  end

  def update
    if @service.update(name: service_params[:name], config: service_config_params)
      redirect_to services_path, notice: "Service updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy!
    redirect_to services_path, notice: "Service deleted."
  end

  # POST /services/test_connection
  # Probes a service's connectivity using the (unsaved) config from the form,
  # responding with a turbo stream that updates the form's status indicator.
  def test_connection
    klass = service_klass
    config = service_config_params

    begin
      klass.new(user: Current.user, name: service_params[:name], config: config).test_connection(config)
      @connected = true
    rescue StandardError => e
      @connected = false
      @message = e.message
    end
  end

  private

  # OAuth services aren't created up-front. The form carries a name and an
  # OAuth client choice; we create the client credential (if a new one was
  # entered) and hand off to the OAuth dance. The service row is only created
  # in the OAuth callback after a successful exchange.
  def create_oauth_service
    klass = service_klass
    @service = klass.new(name: service_params[:name])
    load_oauth_clients

    unless @service.name.presence
      @service.errors.add(:name, "can't be blank")
      return render(:new, status: :unprocessable_entity)
    end

    credential = resolve_oauth_client_credential
    unless credential
      @service.errors.add(:base, "Choose an OAuth client or add new client credentials")
      return render(:new, status: :unprocessable_entity)
    end

    redirect_to oauth_start_path(kind: klass.kind, name: @service.name, oauth_client_credential_id: credential.id)
  end

  # Resolves the client credential the form selected: an existing one (owned by
  # the user) or a freshly created (and saved) one from the nested fields.
  def resolve_oauth_client_credential
    if params[:oauth_client_credential_id].present? && params[:oauth_client_credential_id] != "new"
      Current.user.oauth_client_credentials.find_by(id: params[:oauth_client_credential_id])
    elsif params[:oauth_client_credential].present?
      cred_params = params.require(:oauth_client_credential).permit(:name, :client_id, :client_secret)
      return nil if cred_params[:name].blank? || cred_params[:client_id].blank? || cred_params[:client_secret].blank?

      provider = service_klass.respond_to?(:oauth_provider) ? service_klass.oauth_provider.to_s : "google"
      Current.user.oauth_client_credentials.create!(cred_params.merge(provider: provider))
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def load_oauth_clients
    provider = @service.respond_to?(:provider) ? @service.provider : nil
    @clients = provider.present? ? Current.user.oauth_client_credentials.where(provider: provider) : []
  end

  def set_service
    @service = Current.user.services.find(params[:id])
  end

  def service_klass
    Service.class_for_kind(service_params[:kind]) || Service.class_for_kind(Service.kinds.first)
  end

  def service_params
    params.require(:service).permit(:name, :kind)
  end

  def service_config_params
    return {} unless params[:service].key?(:config)

    klass = @service&.class || service_klass
    keys = klass.config_fields.keys.map(&:to_s)
    params.require(:service).require(:config).permit(*keys)
  end
end
