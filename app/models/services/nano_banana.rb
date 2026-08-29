# frozen_string_literal: true

require "faraday"
require "json"

module Services
  # Google's Nano Banana family of image generation models, exposed as a native
  # presa service. Three tools: `generate_image` (text prompt -> image),
  # `edit_image` (existing image + prompt -> edited image) and `list_models`
  # (available Nano Banana models, ids agents can pass to the other two tools).
  #
  # The Gemini API receives the prompt and (for edits) a base64-encoded image as
  # `inline_data`; results come back in the first candidate's inline_data.
  # Images are returned inline as `data:` URIs so nothing is stored or uploaded.
  #
  # `generate_image`/`edit_image` take an optional `model:`; defaults to the
  # latest flash-tier model and validates against AVAILABLE_MODELS.
  class NanoBanana < Service
    kind :nano_banana
    icon "gemini.png"
    category :media

    config_field :api_key, required: true, secret: true

    GEMINI_URL = "https://generativelanguage.googleapis.com"
    MAX_PROMPT_LENGTH = 1000
    MAX_IMAGE_BYTES = 32 * 1024 * 1024

    # Model id => human label. The default is the newest flash-tier image model.
    AVAILABLE_MODELS = {
      "gemini-3.1-flash-image"      => "Nano Banana 2",
      "gemini-3.1-flash-lite-image" => "Nano Banana 2 Lite",
      "gemini-3-pro-image"          => "Nano Banana Pro",
      "gemini-2.5-flash-image"      => "Nano Banana"
    }.freeze
    DEFAULT_MODEL = "gemini-3.1-flash-image"

    def list_models
      AVAILABLE_MODELS.map { |id, label| { id: id, label: label, default: id == DEFAULT_MODEL } }
    end

    def generate_image(prompt, model: DEFAULT_MODEL)
      response = call_gemini(model: validate_model!(model),
                             contents: [ { role: "user", parts: [ { text: prompt } ] } ])
      data_uri_from(response)
    end

    def edit_image(prompt:, image_uri:, model: DEFAULT_MODEL)
      image_bytes, image_mime = fetch_image(image_uri)
      contents = [ {
        role: "user",
        parts: [
          { text: prompt },
          { inline_data: { mime_type: image_mime, data: Base64.strict_encode64(image_bytes) } }
        ]
      } ]
      data_uri_from(call_gemini(model: validate_model!(model), contents: contents))
    end

    def test_connection(config = nil)
      validate_required_config!(config)
      cfg = normalize_config(config)

      res = Faraday.get("#{GEMINI_URL}/v1beta/models", { key: cfg[:api_key].to_s })
      raise "Nano Banana returned status #{res.status}: #{error_snippet(res.body)}" unless res.success?

      true
    end

    private

    def call_gemini(model:, contents:)
      res = Faraday.post(auth_url(config[:api_key], model)) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(contents: contents)
      end
      raise "Nano Banana returned status #{res.status}: #{error_snippet(res.body)}" unless res.success?

      JSON.parse(res.body)
    end

    def auth_url(api_key, model)
      "#{GEMINI_URL}/v1beta/models/#{model}:generateContent?key=#{api_key}"
    end

    def validate_model!(model)
      id = model.to_s
      unless AVAILABLE_MODELS.key?(id)
        raise "Unknown Nano Banana model #{model.inspect}; available: #{AVAILABLE_MODELS.keys.join(", ")}"
      end
      id
    end

    def data_uri_from(response)
      part = response.dig("candidates", 0, "content", "parts")&.last
      raise "Nano Banana returned no image data" if part.blank? || part["inlineData"].blank?

      mime = part.dig("inlineData", "mimeType").presence || "image/png"
      data = part.dig("inlineData", "data")
      raise "Nano Banana returned no image data" if data.blank?

      "data:#{mime};base64,#{data}"
    end

    def fetch_image(image_uri)
      if image_uri.to_s.start_with?("data:")
        mime, _, b64 = image_uri.to_s.partition(",")
        return Base64.decode64(b64), mime.sub(/\Adata:/, "").split(";").first
      end

      res = Faraday.get(image_uri) { |req| req.options.timeout = 30 }
      raise "Failed to fetch image from URL (status #{res.status})" unless res.success?

      bytes = res.body
      raise "Image too large (max #{MAX_IMAGE_BYTES / 1024 / 1024}MB)" if bytes.bytesize > MAX_IMAGE_BYTES

      [ bytes, mime_from(res.headers) ]
    end

    def mime_from(headers)
      mime = headers["content-type"].to_s.split(";").first&.strip
      mime.presence_in(%w[image/jpeg image/png image/webp]) || "image/png"
    end

    def error_snippet(body)
      text = body.to_s.strip
      text = text[0, 300]
      text.empty? ? "no response body" : text
    end
  end
end
