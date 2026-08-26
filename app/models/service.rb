class Service < ApplicationRecord
  belongs_to :user
  has_many :workspace_services, dependent: :destroy
  has_many :workspaces, through: :workspace_services

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
  end

  def kind
    self.class.kind
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
    (super || {}).with_indifferent_access
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
