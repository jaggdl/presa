require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Presa
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Allow reading unencrypted data for encrypted columns. This lets test
    # fixtures store plaintext and is intended for migration out of encrypted
    # attributes over time. New writes are always encrypted.
    config.active_record.encryption.support_unencrypted_data = true

    # Zeitwerk autoloads service subclasses lazily, but Service.kinds needs them
    # all loaded to enumerate the available kinds. Require them at boot/reload.
    config.to_prepare do
      Rails.root.glob("app/models/services/*.rb").each { |file| require file }
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
