# frozen_string_literal: true

module Registry
  # Base class for a single preset: holds the YAML payload for one service and
  # exposes the fields shared by every preset kind (title, category, tags,
  # markdown description, icon). Subclasses declare their YAML directory (via
  # `.directory`) and add the fields specific to their preset kind.
  class Preset
    attr_reader :namespace, :data

    def initialize(namespace, data)
      @namespace = namespace.to_s
      @data = data.is_a?(Hash) ? data : {}
    end

    def title
      data["title"].to_s.presence || namespace.humanize
    end

    def category
      data["category"].to_s.presence || "general"
    end

    def tags
      Array(data["tags"]).map(&:to_s).compact_blank
    end

    # Markdown description, same shape as `docs/services/*.md` (a leading
    # top-level heading is dropped when rendered).
    def description
      text = data["description"].to_s
      return nil if text.blank?

      text.gsub(/\r\n?/, "\n").sub(/\A\s*\n?^#.*$\n?/, "").strip
    end

    # The icon file name in `registry/icons` for this preset, e.g.
    # "nextcloud.jpg". Resolution is by convention (`<namespace>.<ext>`) so the
    # yml doesn't need to name its own asset.
    def icon_filename
      Registry::ICON_EXTENSIONS.each do |ext|
        path = Registry.icons_dir.join("#{namespace}.#{ext}")
        return "#{namespace}.#{ext}" if path.file?
      end
      nil
    end

    # The absolute Pathname of the preset's icon file, or nil when the preset
    # has no icon in `registry/icons`.
    def icon_path
      filename = icon_filename
      return nil if filename.blank?

      path = Registry.icons_dir.join(filename)
      path.file? ? path : nil
    end

    # The directory holding this preset kind's YAML files, e.g.
    # `registry/openapi`. Implemented by each preset kind class.
    def self.directory
      raise NotImplementedError, "#{name} must implement .directory"
    end
  end
end
