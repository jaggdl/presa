class OauthController < ApplicationController
  STATE_TTL = 10.minutes

  # GET /oauth/start
  # Two modes:
  #   * reconnect an existing service:  ?service_id=&oauth_client_credential_id=
  #   * create a new service via OAuth: ?kind=&name=&oauth_client_credential_id=
  # Builds a signed state and bounces the user to the provider's consent screen.
  def start
    credential = Current.team.oauth_client_credentials.find(params[:oauth_client_credential_id])

    if params[:service_id].present?
      service = Current.team.services.find(params[:service_id])
      raise ActiveRecord::RecordNotFound unless service.is_a?(OauthService)

      state = oauth_verifier.generate(
        { "service_id" => service.id, "oauth_client_credential_id" => credential.id },
        expires_in: STATE_TTL, purpose: "oauth_start"
      )
      redirect_to service.authorize_url(redirect_uri: oauth_callback_url, state: state), allow_other_host: true
    else
      klass = service_class_for_kind(params[:kind])
      state = oauth_verifier.generate(
        {
          "kind" => klass.kind,
          "name" => params[:name].to_s.presence,
          "oauth_client_credential_id" => credential.id
        },
        expires_in: STATE_TTL, purpose: "oauth_start"
      )
      redirect_to klass.authorize_url_for(client: credential, redirect_uri: oauth_callback_url, state: state),
                  allow_other_host: true
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to services_path, alert: "That OAuth service could not be found."
  end

  # GET /oauth/callback?code=&state=
  # Verifies the state, exchanges the code for tokens, and persists the grant.
  # For the new-service flow the service itself is created here, only after a
  # successful exchange (so a cancelled/failed OAuth leaves no row behind).
  def callback
    state = oauth_verifier.verify(params[:state], purpose: "oauth_start")
    credential = Current.team.oauth_client_credentials.find(state.fetch("oauth_client_credential_id"))

    if params[:code].blank?
      target = state["service_id"].present? ? service_path(state["service_id"]) : services_path
      redirect_to target, alert: "Authorization was not completed."
      return
    end

if state["service_id"].present?
      reconnect_existing!(state, credential)
else
      create_new_service!(state, credential)
end
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to services_path, notice: "The OAuth request could not be validated; please try again."
  rescue StandardError => e
    redirect_to services_path, alert: "Failed to connect: #{e.message}"
  end

  private

  def reconnect_existing!(state, credential)
    service = Current.team.services.find(state["service_id"])
    raise ActiveRecord::RecordNotFound unless service.is_a?(OauthService)

    service.acquire_credentials!(code: params[:code], redirect_uri: oauth_callback_url, client_credential: credential)
    redirect_to service_path(service), notice: "Connected #{provider_label(service)}."
  end

  def create_new_service!(state, credential)
    klass = service_class_for_kind(state["kind"])
    name = state["name"].to_s.presence
    raise "Service name can't be blank" if name.blank?

    service = klass.new(team: Current.team, name: name)
    tokens = service.exchange_tokens(code: params[:code], redirect_uri: oauth_callback_url, client_credential: credential)
    service.store_grant!(tokens: tokens, client_credential: credential)
    service.save!
    redirect_to service_path(service), notice: "Service created and connected."
  end

  def service_class_for_kind(kind)
    klass = Service.class_for_kind(kind)
    raise ActiveRecord::RecordNotFound unless klass && klass <= OauthService

    klass
  end

  def oauth_verifier
    @oauth_verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
  end

  def provider_label(service)
    service.respond_to?(:provider) && service.provider.presence || "the provider"
  end
end
