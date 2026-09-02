# frozen_string_literal: true

# Installs checked-in registry presets (registry/) into real service kinds. A
# preset is the metadata + spec source for a service; installing it creates the
# actual record the app runs on and sends the user to the new-service page so
# they can connect it. All the heavy lifting lives on the preset loaders
# (`Registry::Openapi.install`, ...); this controller only wires the type to its
# loader and handles the outcome.
class RegistryController < ApplicationController
  # Preset type => loader. Adding a new preset kind (e.g. MCP) is a one-line
  # registration here plus its loader (`Registry::Mcp.install`).
  INSTALLERS = {
    "openapi" => Registry::Openapi
  }.freeze

  # POST /registry/:type/:name/install
  def install
    loader = INSTALLERS[params[:type].to_s]
    raise ArgumentError, "Unsupported preset type '#{params[:type]}'" unless loader

    kind = loader.install(params[:name], team: Current.team)
    if kind.persisted?
      redirect_to new_kind_service_services_path(kind.namespace), notice: "Preset '#{kind.title}' installed. Create a service from it."
    else
      redirect_to services_path, alert: "Could not install preset: #{kind.errors.full_messages.to_sentence.presence || "unknown error"}"
    end
  rescue Openapi::Parser::Error => e
    redirect_to services_path, alert: "Could not install preset: #{e.message}"
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    redirect_to services_path, alert: e.message
  end
end
