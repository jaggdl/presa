# frozen_string_literal: true

require "fileutils"
require "securerandom"

# Short-lived on-disk store for images uploaded through a tool call. Tools
# write bytes here and hand out a temporary URL (see `TempImagesController`);
# a background job deletes the file after use so nothing accumulates. Files get
# an unguessable name, are chmod 600, and are swept once past `TTL`.
module TempImageStore
  DIRECTORY = Rails.root.join("tmp", "temp_images")
  TTL = 15.minutes
  MIME_SUFFIX = ".mime"

  class << self
    def save(bytes, mime:)
      FileUtils.mkdir_p(DIRECTORY)
      token = SecureRandom.urlsafe_base64(12)
      File.binwrite(DIRECTORY.join(token), bytes)
      File.binwrite(DIRECTORY.join("#{token}#{MIME_SUFFIX}"), mime.to_s)
      File.chmod(0o600, DIRECTORY.join(token))
      token
    end

    def read(filename)
      path = DIRECTORY.join(filename)
      return nil unless path.exist? && path.to_s.start_with?(DIRECTORY.to_s) && File.file?(path)

      path.binread
    end

    def mime_for(filename)
      mime = File.read(DIRECTORY.join("#{filename}#{MIME_SUFFIX}")).strip
      Rack::Mime::MIME_TYPES.fetch(mime, mime).presence || "application/octet-stream"
    rescue Errno::ENOENT
      "application/octet-stream"
    end

    # Deletes a stored file and its mime sidecar (best-effort, path-traversal
    # guarded).
    def delete(filename)
      path = DIRECTORY.join(filename)
      return unless path.to_s.start_with?(DIRECTORY.to_s)

      File.delete(path) if path.exist?
      File.delete(DIRECTORY.join("#{filename}#{MIME_SUFFIX}")) if DIRECTORY.join("#{filename}#{MIME_SUFFIX}").exist?
    rescue Errno::ENOENT
      nil
    end

    # Deletes stored files (and their mime sidecars) older than `older_than`,
    # keeping the directory from growing indefinitely. Safe to call on every
    # upload/serve.
    def sweep!(older_than: TTL.ago)
      return unless DIRECTORY.exist?

      DIRECTORY.each_child do |path|
        File.delete(path) if path.mtime < older_than
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
