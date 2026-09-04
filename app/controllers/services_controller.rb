class ServicesController < ApplicationController
  before_action :set_service, only: %i[ show update destroy ]

  def index
    @services = Service.with_invocation_counts(Current.team.services.includes(:workspaces).order(:type, :name))
    # Prefetch remote tool lists in parallel so the per-row tool counts don't
    # trigger a serial MCP discovery round-trip per service.
    Services::Mcp.warm_remote_tools(@services)

    @q = params[:q].to_s.strip
    @offset = [ params[:offset].to_i, 0 ].max
    matching_kinds = Service.search_kinds(term: @q)
    @kinds = matching_kinds.drop(@offset).first(Service::KINDS_PER_PAGE)
    @show_more = (@offset + @kinds.length) < matching_kinds.length

    # Only the as-you-type search ("Show more" carries offset, search carries q)
    # asks for the grid-refresh stream. An unsafe form submission elsewhere
    # (e.g. the edit form on /services/:id) follows its 302 back to bare /services
    # with turbo-stream advertised in Accept; without gating on q/offset Rails
    # would answer that navigation with this grid partial instead of a full page,
    # so the redirect silently goes nowhere.
    if request.format.turbo_stream? && (params.key?(:q) || params.key?(:offset))
      grid_action = @offset.zero? ? "replace" : "append"
      render turbo_stream: [
        turbo_stream.public_send(grid_action, "kinds-grid", partial: "services/kinds_grid", locals: { kinds: @kinds, q: @q, append: !@offset.zero? }),
        turbo_stream.replace("kinds-more", partial: "services/kinds_more",
                             locals: { q: @q, offset: @offset + @kinds.length, show_more: @show_more })
      ]
    else
      render :index
    end
  end

  def new
    klass = Service.class_for_kind(params[:kind]) || Service.class_for_kind(Service.kinds.first)
    @service = klass.new
    load_oauth_clients
  end

  def create
    # An OpenAPI service created via the OAuth method bounces to the provider
    # (like OAuthService kinds) instead of saving a row up-front; the row is
    # built in the OAuth callback after a successful exchange.
    if openapi_oauth_create?
      return create_oauth_service(cred_type: "oauth")
    end

    if service_klass <= OauthService
      return create_oauth_service
    end

    klass = service_klass
    @service = if klass <= Services::Openapi && klass.openapi_kind
      klass.openapi_kind.services.build(team: Current.team, name: service_params[:name], config: service_config_params)
    else
      klass.new(team: Current.team, name: service_params[:name], config: service_config_params)
    end

    if @service.save
      redirect_to services_path, notice: "Service created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tools = ApplicationTool.expose_for(@service)
  end

  def update
    # OpenAPI services keep their spec/namespace on the kind; an update touches
    # only the submitted per-service fields (credentials, base URL override,
    # health pickers), merged so untouched slots stay stored.
    if @service.is_a?(Services::Openapi)
      config = @service.config.merge(service_config_params)
      if @service.update(name: service_params[:name], config: config)
        redirect_to service_path(@service), notice: "Service updated."
      else
        @tools = ApplicationTool.expose_for(@service)
        render :show, status: :unprocessable_entity
      end
      return
    end

    if @service.update(name: service_params[:name], config: service_config_params)
      redirect_to service_path(@service), notice: "Service updated."
    else
      @tools = ApplicationTool.expose_for(@service)
      render :show, status: :unprocessable_entity
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

    # OpenAPI integrations keep their spec + namespace in stored config; the
    # connection form only carries credential slots, so probe with stored +
    # submitted config merged.
    if @service&.is_a?(Services::Openapi)
      config = @service.config.merge(config)
    end

    begin
      service = klass.new(team: Current.team, name: service_params[:name], config: config)
      @connected = service.test_connection(config)
      @health_label = service.health_label if service.respond_to?(:health_label)
    rescue StandardError => e
      @connected = false
      @message = e.message
    end
  end

  private

  # OAuth services aren't created up-front. The form carries a name and an
  # OAuth client choice; we create the client credential (if a new one was
  # entered) and hand off to the OAuth dance. The service row is only created
  # in the OAuth callback after a successful exchange. `cred_type` (e.g.
  # "oauth") is carried in the signed state for OpenAPI services, which record
  # their chosen auth method in config; OAuthService kinds ignore it.
  def create_oauth_service(cred_type: nil)
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

    start_params = { kind: klass.kind, name: @service.name, oauth_client_credential_id: credential.id }
    start_params[:cred_type] = cred_type if cred_type.present?
    redirect_to oauth_start_path(start_params)
  end

  # True when the submitted form asks to create an OpenAPI service via OAuth
  # (spec declares an OAuth scheme and the user picked the OAuth method).
  def openapi_oauth_create?
    klass = service_klass
    klass <= Services::Openapi &&
      klass.oauth_provider.present? &&
      params.dig(:service, :config, :cred_type).to_s == "oauth"
  end

  # Resolves the client credential the form selected: an existing one (owned by
  # the user) or a freshly created (and saved) one from the nested fields.
  def resolve_oauth_client_credential
    if params[:oauth_client_credential_id].present? && params[:oauth_client_credential_id] != "new"
      Current.team.oauth_client_credentials.find_by(id: params[:oauth_client_credential_id])
    elsif params[:oauth_client_credential].present?
      cred_params = params.require(:oauth_client_credential).permit(:name, :client_id, :client_secret, :scope)
      return nil if cred_params[:name].blank? || cred_params[:client_id].blank? || cred_params[:client_secret].blank?

      provider = service_klass.respond_to?(:oauth_provider) ? service_klass.oauth_provider.to_s : "google"
      Current.team.oauth_client_credentials.create!(cred_params.merge(provider: provider))
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def load_oauth_clients
    provider = @service.respond_to?(:provider) ? @service.provider : nil
    @clients = provider.present? ? Current.team.oauth_client_credentials.where(provider: provider) : []
  end

  def set_service
    @service = Current.team.services.find(params[:id])
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
    openapi_kind = @service.openapi_kind if @service.is_a?(Services::Openapi)
    openapi_kind ||= klass.openapi_kind if klass.respond_to?(:openapi_kind) && klass <= Services::Openapi

    # OpenAPI services store their schema on the kind (security schemes + extra
    # credentials), plus the per-service single-credential type chooser
    # (cred_type/cred_name/cred_value), base URL override and health fields.
    # Pre-kind rows fall back to their instance-derived schema.
    if openapi_kind
      schema = Services::Openapi.credential_schema(openapi_kind)
      return params.require(:service).require(:config).permit(*schema.keys, :base_url, :cred_type, :cred_name, :cred_value)
    elsif @service&.is_a?(Services::Openapi)
      return params.require(:service).require(:config).permit(*@service.config_schema.keys)
    end

    schema = klass.config_fields
    scalar_keys = []
    array_keys = []
    schema.each do |field, opts|
      opts[:array] ? array_keys << field.to_s : scalar_keys << field.to_s
    end

    if array_keys.any?
      params.require(:service).require(:config).permit(*scalar_keys, array_keys.to_h { |k| [ k, [] ] })
    else
      params.require(:service).require(:config).permit(*scalar_keys)
    end
  end
end
