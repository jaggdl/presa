# frozen_string_literal: true

require "faraday"

module Openapi
  # Best-effort discovery of a service's icon from its base URL host. Tries the
  # host's own metadata first (the `<link rel="icon">` tags on the root page),
  # then falls back to the conventional `/favicon.ico` and common icon paths.
  # Used when an `OpenapiKind` is created so the kind (and its services) get a
  # recognizable logo in the picker. Never raises: callers should treat a nil
  # result as "no icon found".
  class IconFetcher
    ICON_RE = /<link[^>]+rel=["'](?:shortcut\s+)?icon["'][^>]*>/i
    HREF_RE = /href=["']([^"']+)["']/i
    FALLBACK_PATHS = %w[/favicon.ico /apple-touch-icon.png /icon.png].freeze
    FETCH_TIMEOUT = 10
    MAX_ICON_BYTES = 5 * 1024 * 1024

    class << self
      # Returns `[bytes, mime_type]` for the best icon it can find for
      # `base_url`, or nil when nothing usable was found.
      def fetch(base_url)
        new(base_url).fetch
      end

      def connection
        Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.response :raise_error
          faraday.adapter Faraday.default_adapter
          faraday.options.timeout = FETCH_TIMEOUT
          faraday.options.open_timeout = FETCH_TIMEOUT
        end
      end
    end

    def initialize(base_url)
      @base_url = base_url.to_s
    end

    def fetch
      return nil if host.blank?

      each_candidate do |url|
        bytes, mime = download(url)
        return [ bytes, mime ] if bytes && image?(mime, url)
      end
      nil
    rescue StandardError
      nil
    end

    private

    def host
      uri = URI(@base_url)
      return nil unless %w[http https].include?(uri.scheme)

      uri.host
    rescue URI::InvalidURIError
      nil
    end

    def root_url
      uri = URI(@base_url)
      "#{uri.scheme}://#{uri.host}"
    end

    def each_candidate
      (declared_icons + FALLBACK_PATHS).each do |path|
        yield URI.join(root_url, path).to_s
      end
    end

    # The icon URLs declared by the host's root page metadata.
    def declared_icons
      html = download_html(root_url)
      return [] if html.blank?

      html.scan(ICON_RE).filter_map { |tag| tag.match(HREF_RE)&.[](1) }.reject(&:blank?).uniq
    end

    def download_html(url)
      bytes, mime = download(url)
      return nil unless bytes && mime.to_s.include?("text/html")

      bytes.force_encoding("UTF-8").scrub
    end

    # Downloads `url`, following redirects and capping size/time. Returns
    # `[bytes, mime]` when the response is an image, else nil.
    def download(url)
      response = self.class.connection.get(url) do |req|
        req.headers["User-Agent"] = "Presa-OpenAPI/1"
        req.headers["Accept"] = "image/*,text/html"
      end
      bytes = response.body
      return nil if bytes.bytesize > MAX_ICON_BYTES

      mime = response.headers["content-type"].to_s.split(";").first.to_s.downcase
      [ bytes, mime.presence || "application/octet-stream" ]
    rescue Faraday::Error
      nil
    end

    def image?(mime, url)
      return true if mime.to_s.start_with?("image/")

      %w[.png .jpg .jpeg .gif .svg .webp .avif .ico].any? { |ext| url.downcase.include?(ext) }
    end
  end
end
