class Service < ApplicationRecord
  belongs_to :user
  has_many :workspace_services, dependent: :destroy
  has_many :workspaces, through: :workspace_services
  has_many :tool_invocations, dependent: :destroy

  encrypts :config

  class_attribute :config_kind, default: nil
  class_attribute :config_fields, default: {}
  class_attribute :config_icon, default: nil
  class_attribute :config_icon_invert, default: false
  class_attribute :config_category, default: nil

  # Domain categories, declared per service implementation. A virtual attribute
  # (no column): each subclass's class-level `category` DSL sets the default,
  # applied to new instances on initialize.
  attribute :category, :string
  enum :category, {
    development: "development",
    productivity: "productivity",
    knowledge: "knowledge",
    social: "social",
    media: "media",
    automation: "automation",
    fitness: "fitness",
    general: "general"
  }

  validates :name, presence: true, uniqueness: { scope: %i[user_id type] }

  before_validation :apply_config_defaults
  after_initialize :apply_category_default
  validate :config_fields_present

  class << self
    def kind(value = nil)
      self.config_kind = value.to_s if value
      config_kind || (name || "").demodulize.chomp("Service").underscore.presence
    end

    # Declares the brand image for this service kind (filename under
    # app/assets/images, e.g. "github.png").
    def icon(value = nil)
      self.config_icon = value.to_s if value
      config_icon
    end

    # Declares whether this kind's image needs CSS inversion to read as
    # light-on-dark (e.g. a black logo on a dark theme).
    def invert_icon(value = true)
      self.config_icon_invert = value
    end

    # The domain category for this service kind (e.g. `:development`,
    # `:productivity`, `:media`). Declaring it sets the default category
    # applied to instances of this kind; unset kinds fall back to `:general`.
    def category(value = nil)
      self.config_category = value.to_s if value
      config_category || "general"
    end

    # The Markdown description for this service kind, read from
    # `docs/services/<kind>.md` when present. A leading top-level heading used
    # as a doc title is dropped from the rendered description.
    def description
      path = Rails.root.join("docs/services/#{kind}.md")
      return nil unless path.exist?

      path.read.sub(/\A\s*#[^\n]*\n+/, "").strip
    end

    # Concrete service subclasses available to instantiate (e.g. Services::Github).
    # Subclasses are loaded at boot/reload via config/application.rb to_prepare,
    # so this sees them all. Anonymous subclasses (e.g. a `Class.new(Service)`
    # created in a test) have no name and are skipped.
    def concrete_service_classes
      Service.descendants.select { |klass| klass.name.present? }
    end

    def kinds
      concrete_service_classes.filter_map { |klass| klass.kind if offerable?(klass) }
    end

    # A kind is offerable when its class declares config fields (plain services
    # and the generic MCP server) or its own machine kind (OAuth leaves like
    # Gmail, MCP presets like Parallel). Abstract bases (Service, OauthService)
    # declare neither and so are never offerable.
    def offerable?(klass)
      klass.config_fields.present? || klass.config_kind.present?
    end

    def class_for_kind(kind)
      concrete_service_classes.find { |klass| klass.kind == kind && offerable?(klass) }
    end

    def config_field(name, required: false, secret: false, default: nil, textarea: false)
      self.config_fields = config_fields.merge(name.to_sym => { required: required, secret: secret, default: default, textarea: textarea })
    end

    # Decorates each service in `relation` with its invocation count since
    # `since`, using a single grouped query instead of one per service.
    # `invocation_count` on the returned records then avoids further queries.
    def with_invocation_counts(relation, since: 24.hours.ago)
      services = relation.to_a
      ids = services.map(&:id)
      return services if ids.empty?

      counts = ToolInvocation
        .where(service_id: ids)
        .where("tool_invocations.created_at >= ?", since)
        .group(:service_id)
        .count

      services.each do |service|
        service.instance_variable_set(:@invocation_count, counts.fetch(service.id, 0))
      end
      services
    end
  end

  def kind
    self.class.kind
  end

  # The Markdown description declared for this service kind.
  def description
    self.class.description
  end

  # Number of tool invocations recorded for this service since `since`.
  # Uses the count batch-loaded via `with_invocation_counts` when present,
  # otherwise issues a query for this service alone.
  def invocation_count(since: 24.hours.ago)
    return @invocation_count if @invocation_count

    tool_invocations.where("tool_invocations.created_at >= ?", since).count
  end

  # The brand image filename for this service, or the generic placeholder when
  # the kind has not declared an icon.
  def icon
    self.class.config_icon.presence || "placeholder.png"
  end

  # Whether the icon must be inverted to read on a dark background.
  def invert_icon?
    self.class.config_icon_invert
  end

  def config
    (super || {}).with_indifferent_access.transform_values { |v| v.is_a?(String) ? v.strip : v }
  end

  def config=(value)
    super(value.to_h.stringify_keys)
  end

  def config_schema
    self.class.config_fields.transform_keys(&:to_s)
  end

  private

  # Coerce a config hash (possibly an ActionController::Parameters) into an
  # indifferent-access Hash, falling back to the instance's stored config when
  # none is given. Shared by the services' `test_connection` helpers.
  def normalize_config(config = nil)
    hash = (config || self.config)
    hash = hash.to_unsafe_h if hash.respond_to?(:to_unsafe_h)
    hash.with_indifferent_access
  end

  # Raises unless every required config field is present for the given config.
  # Keeps `test_connection` from reporting success when a mandatory value (e.g.
  # an API key) is missing.
  def validate_required_config!(config = nil)
    missing = self.class.config_fields.filter_map do |field, opts|
      field.to_s if opts[:required] && normalize_config(config)[field.to_sym].blank?
    end
    return if missing.empty?

    raise "#{missing.map { |f| f.humanize }.join(", ")} #{missing.one? ? "is" : "are"} required"
  end

  def apply_config_defaults
    merged = self.class.config_fields.transform_values { |opts| opts[:default] }.compact
    self.config = merged.stringify_keys.merge(config)
  end

  # Persists the class-declared category on new records so the enum column
  # always holds a value, even when bulk-loaded (fixtures).
  def apply_category_default
    self.category = self.class.category if category.blank?
  end

  # Persists the class-declared category onto new instances so the virtual
  # enum attribute always holds a value (the reader, predicates, and scopes
  # work uniformly), defaulting to `general` for undeclared kinds.
  def apply_category_default
    self.category = self.class.category if category.blank?
  end

  def config_fields_present
    config_schema.each do |field, opts|
      errors.add(:config, "#{field} is required") if opts[:required] && config[field.to_sym].blank?
    end
  end
end
