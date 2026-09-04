# frozen_string_literal: true

# STI base for OAuth-backed services (e.g. Gmail). Unlike plain / MCP
# services, an OAuth service carries no user-typed config fields in the form:
# the OAuth *client* (client_id/secret) lives on an OauthClientCredential,
# and the acquired *grant* (access/refresh tokens) lives on an OauthGrant,
# both associated with the service. All shared behaviour lives in
# `Concerns::OauthProvider` (also included by OpenAPI-generated services whose
# spec declares an OAuth scheme); this class only tags the kind and declares
# it as an OAuth service.
class OauthService < Service
  include OauthProvider

  tags :oauth
end
