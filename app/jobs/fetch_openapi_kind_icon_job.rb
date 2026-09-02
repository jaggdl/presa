# frozen_string_literal: true

class FetchOpenapiKindIconJob < ApplicationJob
  # Downloading an icon from an external host can be slow or unavailable, so it
  # runs in the background after a kind is created. A missing icon just leaves
  # the kind (and its services) on the generic placeholder; nothing is raised.
  queue_as :default

  def perform(openapi_kind_id)
    kind = OpenapiKind.find_by(id: openapi_kind_id)
    return if kind.blank?
    return if kind.icon.attached?

    bytes, mime = Openapi::IconFetcher.fetch(kind.base_url)
    return if bytes.blank?

    kind.icon.attach(io: StringIO.new(bytes), filename: "icon#{extension_for(mime)}", content_type: mime)
  end

  private

  def extension_for(mime)
    {
      "image/png" => ".png",
      "image/jpeg" => ".jpg",
      "image/gif" => ".gif",
      "image/webp" => ".webp",
      "image/svg+xml" => ".svg",
      "image/avif" => ".avif",
      "image/vnd.microsoft.icon" => ".ico",
      "image/x-icon" => ".ico"
    }[mime.to_s] || ".png"
  end
end
