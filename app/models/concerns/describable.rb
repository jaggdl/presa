# frozen_string_literal: true

# Adds plain-text and preview rendering of a Markdown description string.
# Services keep their docs in `docs/services/<kind>.md`; the `description`
# method returns the raw Markdown, while `description_plain` strips headings
# and inline formatting (links, emphasis, code) so the text can be searched or
# summarized, and `description_preview` clamps that plain text to a word-safe
# length for compact card layouts.
module Describable
  extend ActiveSupport::Concern

  # The description's Markdown reduced to plain text: heading lines and inline
  # formatting/link markup removed, whitespace collapsed.
  def description_plain
    text = description.to_s
    return "" if text.blank?

    text.gsub(/^\s*#.*$/m, "")
        .gsub(/\*\*([^*]+)\*\*/, '\1')
        .gsub(/\*([^*]+)\*/, '\1')
        .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
        .gsub(/`([^`]*)`/, '\1')
        .gsub(/\s+/, " ")
        .strip
  end

  # A short plain-text preview of the description, clamped to `limit`
  # characters at a word boundary. Returns nil when there is no description.
  def description_preview(limit: 100)
    text = description_plain
    return nil if text.blank?

    text.truncate(limit, separator: " ")
  end
end