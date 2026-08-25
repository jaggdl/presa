class Service < ApplicationRecord
  belongs_to :user
  has_many :workspace_services, dependent: :destroy
  has_many :workspaces, through: :workspace_services

  encrypts :config

  class_attribute :config_kind, default: nil
  class_attribute :config_fields, default: {}

  validates :name, presence: true, uniqueness: { scope: %i[user_id type] }

  before_validation :apply_config_defaults
  validate :config_fields_present

  class << self
    def kind(value = nil)
      self.config_kind = value.to_s if value
      config_kind || name.demodulize.chomp("Service").underscore
    end

    def config_field(name, required: false, secret: false, default: nil)
      self.config_fields = config_fields.merge(name.to_sym => { required: required, secret: secret, default: default })
    end
  end

  def kind
    self.class.kind
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
