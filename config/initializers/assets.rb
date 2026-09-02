# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Registry icons (registry/icons/*) are served through the asset pipeline like
# the static brand images in app/assets/images; presets reference them by file
# name (e.g. "nextcloud.jpg").
icons_dir = Rails.root.join("registry", "icons")
Rails.application.config.assets.paths << icons_dir if icons_dir.directory?
