# frozen_string_literal: true

# A reusable OpenAPI service kind: the parsed definition (title, namespace,
# servers, security schemes, and one entry per operation) is stored here once,
# and every `Services::Openapi` record referencing it is an *instance* of that
# kind with its own name, base URL override, and connected credentials. Team
# namespaces are unique, so the kind reads as a first-class machine kind (e.g.
# "immich") that backs a picker card just like the static service subclasses.
#
# Definition/namespace-level defaults live here (title, default base URL,
# health-check defaults, extra-credential definitions); the per-service values
# (credential fills, base URL override, health overrides) live on the service's
# own encrypted `config`. An icon for the kind (and its services) is fetched
# from the base URL host and stored via Active Storage.
class OpenapiKind < ApplicationRecord
  belongs_to :team

  has_one_attached :icon

  # Services of this kind. Destroy is restricted while instances exist so an
  # onboarded spec can't be dropped out from under live tools.
  has_many :services, class_name: "Services::Openapi", foreign_key: :openapi_kind_id,
                      dependent: :restrict_with_error

  # The full generated definition (same shape as the wizard's transient draft:
  # operations, servers, security slots, response fields). Encrypted like the
  # services' config.
  encrypts :definition

  validate :definition_present
  validates :title, presence: true
  validates :namespace, presence: true,
                        format: { with: /\A[a-z0-9_]+\z/, message: "may only contain a-z, 0-9 and underscore" },
                        uniqueness: { scope: :team_id }
  validates :category, inclusion: { in: ->(_) { Service.categories.values },
                                    message: "%{value} is not a valid category" }
  validate :base_url_is_http

  # `name` aliases the display title so the wizard/service forms can treat a
  # kind like the entity they already render (name + errors).
  def name
    title
  end

  def name=(value)
    self.title = value
  end

  # The machine kind the instance services report (`Service#kind`).
  alias_attribute :kind, :namespace

  def definition
    super || {}
  end

  def operations
    list = definition["operations"]
    list.is_a?(Array) ? list : []
  end

  def operation(operation_id)
    operations.find { |op| op["operation_id"].to_s == operation_id.to_s }
  end

  def operation_count
    definition["operation_count"].to_i
  end

  def tag_count
    definition["tag_count"].to_i
  end

  def security_slots
    security = definition["security"]
    security.is_a?(Hash) ? security : {}
  end

  # The primary OAuth scheme slot (the first scheme with a usable
  # authorization-code flow), or nil when the spec declares no OAuth.
  # OAuth is offered once per kind (single provider, Option A): when several
  # schemes are OAuth-capable (e.g. Figma's `OAuth2` + `OrgOAuth2`) the first
  # in spec order wins and the rest stay unreachable as connect flows.
  def oauth_slot
    security_slots.find { |_name, slot| slot["kind"].to_s == "oauth" }&.last
  end

  # The OAuth provider key for services of this kind (the namespace), or nil
  # when the spec declares no OAuth flow. Registered as a dynamic provider on
  # Oauth::Base so client credentials, icons, and the browser dance resolve.
  def oauth_provider
    oauth_slot.present? ? namespace : nil
  end

  def extra_credentials
    list = read_attribute(:extra_credentials)
    list.is_a?(Array) ? list : []
  end

  # Card/subheader description: a stored (wizard-entered or preset) description
  # wins; otherwise the spec's own description, else a short spec-derived
  # summary.
  def description
    read_attribute(:description).to_s.strip.presence ||
      definition["description"].to_s.presence ||
      "#{operation_count} operations across #{tag_count} tag#{"s" unless tag_count == 1}"
  end

  # Kicks off a background job that fetches this kind's icon from its base URL
  # host and attaches it. Runs async so a slow/unavailable icon host never
  # blocks the wizard; a failed fetch simply leaves the generic placeholder.
  def enqueue_icon_fetch!
    FetchOpenapiKindIconJob.perform_later(id) if base_url.present? && !icon.attached?
  end

  private

  def definition_present
    errors.add(:definition, "is missing") if definition.blank?
  end

  def base_url_is_http
    return if base_url.blank?

    uri = URI(base_url)
    errors.add(:base_url, "must be http(s)") unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    errors.add(:base_url, "is invalid")
  end
end
