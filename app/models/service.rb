class Service < ApplicationRecord
  belongs_to :user
  has_many :workspace_services, dependent: :destroy
  has_many :workspaces, through: :workspace_services
  has_many :tool_invocations

  encrypts :config

  class_attribute :config_kind, default: nil
  class_attribute :config_fields, default: {}
  class_attribute :config_icon, default: nil
  class_attribute :config_icon_invert, default: false

  validates :name, presence: true, uniqueness: { scope: %i[user_id type] }

  before_validation :apply_config_defaults
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
      concrete_service_classes.filter_map { |klass| klass.kind if klass.config_fields.present? }
    end

    def class_for_kind(kind)
      concrete_service_classes.find { |klass| klass.kind == kind }
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

  def apply_config_defaults
    merged = self.class.config_fields.transform_values { |opts| opts[:default] }.compact
    self.config = merged.stringify_keys.merge(config)
  end

  def config_fields_present
    config_schema.each do |field, opts|
      errors.add(:config, "#{field} is required") if opts[:required] && config[field.to_sym].blank?
    end
  end
end
