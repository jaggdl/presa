# frozen_string_literal: true

require "base64"
require "json"

module Gmail
  # Sends an email from the connected Gmail account.
  class SendMessageTool < Base
    description "Send an email from the connected Gmail account"
    kind "send_message"

    arguments do
      required(:to).filled(:string).description("Recipient email address")
      required(:subject).filled(:string).description("Email subject")
      required(:body).filled(:string).description("Plain-text body of the email")
      optional(:cc).filled(:string).description("Cc recipient email address")
      optional(:bcc).filled(:string).description("Bcc recipient email address")
    end

    def call(to:, subject:, body:, cc: nil, bcc: nil)
      message = build_mime(to: to, subject: subject, body: body, cc: cc, bcc: bcc)
      gmail_post("/gmail/v1/users/me/messages/send", body: { raw: Base64.urlsafe_encode64(message) })
    end

    private

    def build_mime(to:, subject:, body:, cc:, bcc:)
      headers = [
        "To: #{to}",
        "Subject: #{encode_word(subject)}"
      ]
      headers << "Cc: #{cc}" if cc.present?
      headers << "Bcc: #{bcc}" if bcc.present?
      headers << "MIME-Version: 1.0"
      headers << "Content-Type: text/plain; charset=UTF-8"
      "#{headers.join("\r\n")}\r\n\r\n#{body}"
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
