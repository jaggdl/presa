# frozen_string_literal: true

require "securerandom"

class OpenapiIntegrationsController < ApplicationController
  # The parsed definition travels step1 -> step2 through a short-lived server
  # cache key, keyed by a token the step-2 form carries back. Long enough to
  # cover config edits; wiped on save or after 45 minutes.
  DRAFT_TTL = 45.minutes

  # Step 1: accept a spec URL or raw JSON/YAML, parse + validate it, and answer
  # with the step-2 "configure" view (turbo stream replacing the wizard panel),
  # or an inline error keeping the spec form visible.
  def parse
    definition, _source = build_definition
    token = store_draft(definition)
    @token = token
    @definition = definition
    @entity = OpenapiKind.new(name: definition["title"].presence || "OpenAPI integration", namespace: definition["namespace_slug"].presence)

    render turbo_stream: turbo_stream.replace("openapi-wizard", partial: "openapi_integrations/step2", locals: { definition: @definition, token: @token, entity: @entity })
  rescue Openapi::Parser::Error => e
    @error = e.message
    render turbo_stream: turbo_stream.replace("openapi-wizard", partial: "openapi_integrations/step1", locals: { error: @error, source: params[:source], spec: params[:spec] }), status: :unprocessable_entity
  end

  # Step 2: configure the integration — display name, namespace, description,
  # default base URL, health-check defaults, and extra "add a method"
  # credential definitions — and save it as an `OpenapiKind`. Once saved the
  # kind appears as a picker card from which any number of services can be
  # created. Credentials are never collected here; they are connected on each
  # service's page.
  def create_kind
    definition = consume_draft(params[:draft_token])
    raise Openapi::Parser::Error, "Integration draft expired — please start over" if definition.blank?

    @entity = build_kind(definition)

    if @entity.save
      matching_kinds = Service.search_kinds(term: params[:q].to_s)
      @kinds = matching_kinds.first(Service::KINDS_PER_PAGE)
      flash.now[:notice] = "Integration '#{@entity.title}' added. Create a service from the picker."
      render turbo_stream: [
        turbo_stream.remove("openapi-dialog"),
        turbo_stream.replace("kinds-grid", partial: "services/kinds_grid", locals: { kinds: @kinds, q: params[:q].to_s, append: false }),
        turbo_stream.replace("flash", partial: "layouts/flash")
      ]
    else
      @definition = definition
      render turbo_stream: turbo_stream.replace("openapi-wizard", partial: "openapi_integrations/step2", locals: { definition: @definition, token: params[:draft_token], entity: @entity }), status: :unprocessable_entity
    end
  rescue Openapi::Parser::Error => e
    @error = e.message
    @source = "url"
    @spec = ""
    render turbo_stream: turbo_stream.replace("openapi-wizard", partial: "openapi_integrations/step1", locals: { error: @error }), status: :unprocessable_entity
  end

  private

  def build_definition
    source = params[:source].to_s.in?(%w[url raw]) ? params[:source] : "raw"
    input = params[:spec].to_s

    raw, root = Openapi::Parser.parse(source: source, input: input)
    Openapi::Parser.validate!(raw)

    definition = Openapi::Generator.generate(root, source_url: (source == "url" ? input : nil))
    [ definition, source ]
  end

  def store_draft(definition)
    token = SecureRandom.hex(16)
    Rails.cache.write("openapi_draft:#{token}", definition, expires_in: DRAFT_TTL)
    token
  end

  def consume_draft(token)
    key = "openapi_draft:#{token.to_s.strip}"
    Rails.cache.read(key).tap { Rails.cache.delete(key) }
  end

  def build_kind(definition)
    integration = {}
    params[:integration].to_unsafe_h.each { |key, value| integration[key.to_s] = value }

    namespace = integration["namespace"].to_s.strip.presence || definition["namespace_slug"].presence || "api"
    base_url = integration["base_url"].to_s.strip.presence || definition["base_url"].to_s.presence

    OpenapiKind.new(
      team: Current.team,
      title: integration["name"].to_s.strip.presence || definition["title"].presence || namespace,
      namespace: namespace,
      description: integration["description"].to_s.strip.presence,
      base_url: base_url,
      spec_url: definition["spec_url"],
      definition: definition,
      health_op: integration["health_op"].to_s.strip.presence
    )
  end
end
