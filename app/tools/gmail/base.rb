# frozen_string_literal: true

module Gmail
  # Abstract base for all Gmail tools. Not exposed directly. HTTP transport and
  # OAuth bearer-token injection live on the service (composed via
  # `Oauth::Client`); this base only shapes requests to the Gmail API. Paths
  # are relative to the service's API base (`.../gmail/v1`): a leading slash
  # would make Faraday drop the base path.
  class Base < ApplicationTool
    service_kind :gmail
    abstract_tool true

    # The media-upload endpoint for the Gmail API. The `/upload` URI is used
    # to send the raw RFC 2822 message bytes when the message exceeds the size
    # where base64-in-JSON (`raw`) is efficient (see the Gmail "Upload
    # attachments" guide): https://developers.google.com/workspace/gmail/api/guides/uploads
    GMAIL_UPLOAD_BASE_URL = "https://gmail.googleapis.com/upload/gmail/v1"

    # Simple (single-request) uploads are recommended for files of 5 MB or
    # less. Above that, media data should go to the `/upload` URI rather than
    # a base64 `raw` field inside a JSON body.
    SIMPLE_UPLOAD_SIZE_LIMIT = 5 * 1024 * 1024

    private

    # GET against the Gmail API, returning the parsed JSON body.
    def gmail_get(path, params: {})
      service.client.get(path, params: params)
    end

    # POST against the Gmail API, sending `body` as JSON. Returns the parsed
    # JSON body.
    def gmail_post(path, body:)
      service.client.post(path, body: body)
    end

    # POST `message` (an RFC 2822 formatted message) to the media-upload
    # endpoint (`uploadType=media`), used for large messages. Returns the
    # parsed JSON body.
    def gmail_upload(path, message)
      service.client(base_url: GMAIL_UPLOAD_BASE_URL).post_raw(
        path,
        raw: message,
        content_type: "message/rfc822",
        params: { uploadType: "media" }
      )
    end
  end
end
