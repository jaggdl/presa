# frozen_string_literal: true

require "base64"
require "json"
require "rack/mime"
require "securerandom"

module Gmail
  # Sends an email from the connected Gmail account, optionally with
  # attachments. Messages are built as RFC 2822 MIME: a plain-text single part
  # without attachments, or `multipart/mixed` when attachments are present.
  # Large messages (5 MB+) are sent to the media-upload endpoint
  # (`/upload`, `uploadType=media`) rather than as a base64 `raw` field, per
  # the Gmail uploads guide.
  class SendMessageTool < Base
    description "Send an email from the connected Gmail account, with optional attachments"

    arguments do
      required(:to).filled(:string).description("Recipient email address")
      required(:subject).filled(:string).description("Email subject")
      required(:body).filled(:string).description("Plain-text body of the email")
      optional(:cc).filled(:string).description("Cc recipient email address")
      optional(:bcc).filled(:string).description("Bcc recipient email address")
      optional(:attachments).array(:hash) do
        required(:filename).filled(:string).description("Attachment file name, e.g. report.pdf")
        required(:content).filled(:string).description("Base64-encoded file content")
        optional(:mime_type).filled(:string).description("Attachment MIME type, e.g. application/pdf (inferred from the file name when omitted)")
      end.description("Optional files to attach to the email")
    end

    def call(to:, subject:, body:, cc: nil, bcc: nil, attachments: nil)
      message = build_mime(to: to, subject: subject, body: body, cc: cc, bcc: bcc, attachments: attachments)

      # Attachments inflate a message ~33% when re-encoded base64 inside a JSON
      # `raw` field, so route every attachment send — plus any oversized plain
      # message — through the media-upload endpoint instead.
      if attachments.present? || message.bytesize > self.class::SIMPLE_UPLOAD_SIZE_LIMIT
        gmail_upload("users/me/messages/send", message)
      else
        gmail_post("users/me/messages/send", body: { raw: Base64.urlsafe_encode64(message) })
      end
    end

    private

    def build_mime(to:, subject:, body:, cc:, bcc:, attachments:)
      headers = [
        "To: #{to}",
        "Subject: #{encode_word(subject)}"
      ]
      headers << "Cc: #{cc}" if cc.present?
      headers << "Bcc: #{bcc}" if bcc.present?
      headers << "MIME-Version: 1.0"

      if attachments.blank?
        headers << "Content-Type: text/plain; charset=UTF-8"
        return "#{headers.join("\r\n")}\r\n\r\n#{body}"
      end

      boundary = "===============#{SecureRandom.hex(16)}=="
      headers << %(Content-Type: multipart/mixed; boundary="#{boundary}")
      parts = [ mime_part(boundary, "text/plain; charset=UTF-8", nil, body) ]
      attachments.map { |a| attributes(a) }.each do |attachment|
        parts << mime_part(boundary, mime_type_for(attachment), filename(attachment), content_for(attachment))
      end
      "#{headers.join("\r\n")}\r\n\r\n#{parts.join("\r\n")}\r\n--#{boundary}--"
    end

    # One MIME part inside `boundary`. Attachments are base64 encoded with a
    # `Content-Disposition` header; the text body part carries none.
    def mime_part(boundary, mime_type, filename, content)
      headers = [ "Content-Type: #{mime_type}" ]
      if filename
        headers << "Content-Transfer-Encoding: base64"
        headers << %(Content-Disposition: attachment; filename="#{encode_filename(filename)}")
      end
      [ "--#{boundary}", *headers, "", content ].join("\r\n")
    end

    def mime_type_for(attachment)
      attachment[:mime_type].presence || infer_mime_type(attachment[:filename])
    end

    def filename(attachment)
      attachment[:filename]
    end

    # The attachment's on-the-wire content: re-encode the input (already
    # base64) folded to the 76-char MIME lines, stripping any whitespace.
    def content_for(attachment)
      Base64.strict_encode64(binary(attachment[:content])).scan(/.{1,76}/).join("\r\n")
    end

    def binary(base64)
      Base64.strict_decode64(base64.to_s.gsub(/\s/, ""))
    rescue ArgumentError
      raise ArgumentError, "attachment content must be valid base64"
    end

    def attributes(attachment)
      attachment.with_indifferent_access
    end

    def infer_mime_type(filename)
      mime = Rack::Mime.mime_type(File.extname(filename.to_s).downcase)
      mime.presence || "application/octet-stream"
    end

    # Header-safe file name: quoted-string, with quotes/backslashes stripped
    # and non-ASCII replaced. Full RFC 2231/2047 encoding is overkill for a
    # file display name; Gmail renders this field as-is.
    def encode_filename(filename)
      filename.to_s.gsub(/["\\\r\n]/, "").gsub(/[^\x20-\x7E]/, "_")
    end

    # RFC 2047 encoded-word for non-ASCII header values (e.g. accents in the
    # subject). Mail headers must stay ASCII; leaving raw UTF-8 bytes in a
    # header makes clients decode them as Latin-1 and show mojibake ("ó" → "Ã³").
    def encode_word(value)
      return value if value.ascii_only?

      "=?UTF-8?B?#{Base64.strict_encode64(value)}?="
    end
  end
end
