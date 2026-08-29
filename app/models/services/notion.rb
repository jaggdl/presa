# frozen_string_literal: true

require "uri"

module Services
  # Notion, backed by Notion's own OAuth (per-service BYO client). The user
  # adds a Notion integration's OAuth client credential and authorizes a
  # workspace; the service then exposes Notion tools (search, read/write pages
  # and databases, page blocks) carrying the acquired grant's token. Notion
  # issues access tokens that never expire, so there is no refresh flow — the
  # stored token is used as-is.
  class Notion < ::OauthService
    kind :notion
    icon "notion.png"
    category :productivity

    self.oauth_provider = :notion
    self.oauth_api_base_url = "https://api.notion.com/v1"
    self.oauth_api_headers = { "Notion-Version" => "2022-06-28" }
    self.oauth_client_auth = :basic

    # Notion's consent screen is the only provider here without OAuth scopes;
    # instead the user chooses which workspace to let the integration into.
    # The authorize URL therefore carries only Notion's own params (a
    # workspace owner), unlike the Google-style scope/offline parameters the
    # shared `OauthService.authorize_url_for` appends for other providers.
    def self.authorize_url_for(client:, redirect_uri:, state:)
      params = {
        client_id: client.client_id,
        response_type: "code",
        owner: "workspace",
        redirect_uri: redirect_uri,
        state: state
      }
      "#{provider_class.authorize_uri}?#{URI.encode_www_form(params)}"
    end
  end
end
