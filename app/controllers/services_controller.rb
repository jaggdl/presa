class ServicesController < ApplicationController
  before_action :set_service, only: %i[ show edit update destroy ]

  def index
    @services = Current.user.services.order(:type, :name)
    # Available service kinds a user can add, MCP first then alphabetical.
    @kinds = Service.kinds.sort_by { |kind| [ kind == "mcp" ? 0 : 1, kind ] }
  end

  def new
    klass = Service.class_for_kind(params[:kind]) || Service.class_for_kind(Service.kinds.first)
    @service = klass.new
  end

  def create
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

  private

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
